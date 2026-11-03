package com.fuli.invest.service;

import com.fuli.invest.dto.response.PositionDTO;
import com.fuli.invest.dto.response.PositionSummaryResponse;
import com.fuli.invest.entity.*;
import com.fuli.invest.repository.AccountRepository;
import com.fuli.invest.repository.PositionRepository;
import com.fuli.invest.repository.TradeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * 持仓聚合服务。
 *
 * MVP 简化说明（重要，接入真实业务前请再评估）：
 * - 期权买卖没有区分"开仓"和"平仓"两个独立标记位，这里按 BUY_* = 开多头仓位 / SELL_* = 开空头（义务）仓位
 *   处理；如果需要"卖出以平掉已买入的多头期权"这种场景，需要在表单里加一个 isClose 开关，
 *   由前端传入后这里再按平仓分支处理，而不是像现在一样一律按"新开/加仓"聚合。
 * - 加权平均成本法：加仓时按数量加权重新计算成本价；减仓/平仓只减少数量，不改变成本价。
 * - currentPrice 没有对接行情数据源，新开仓位时默认等于成本价（浮动盈亏从 0 开始），
 *   后续由用户在持仓详情里手动更新，或由你接入的行情任务定时刷新。
 * - 编辑/删除交易不做增量"撤销"运算（加权平均成本一旦被后续交易稀释就很难精确逆推），
 *   而是简单粗暴但正确：整个用户的持仓在每次交易变更后，从全部历史交易重新聚合一遍
 *   （见 recomputeAll）。用户数据量在这个场景下不大，全量重算的开销可以接受。
 */
@Service
@RequiredArgsConstructor
public class PositionService {

    private final PositionRepository positionRepository;
    private final AccountRepository accountRepository;
    private final TradeRepository tradeRepository;

    /** 交易新增/编辑/删除后统一调用：清空该用户的持仓聚合表，按时间顺序重放全部交易重新生成。 */
    @Transactional
    public void recomputeAll(Long userId) {
        positionRepository.deleteAll(positionRepository.findByUserIdOrderByUpdatedAtDesc(userId));
        List<Trade> all = tradeRepository.findByUserIdAndTradeTimeBetween(
                        userId, LocalDate.now().minusYears(20).atStartOfDay(), LocalDate.now().plusDays(1).atStartOfDay())
                .stream()
                .sorted(Comparator.comparing(Trade::getTradeTime))
                .toList();
        for (Trade t : all) {
            applyTrade(t);
        }
    }

    /** 单笔交易对持仓的增量影响，仅供 recomputeAll 按时间顺序重放调用。 */
    private void applyTrade(Trade trade) {
        TradeDirection posDirection = TradeDirectionRules.positionDirection(trade.getDirection());
        boolean isOpening = TradeDirectionRules.isOpening(trade.getDirection());

        Optional<Position> existing = positionRepository.findByUserIdAndAccountIdAndInstrumentTypeAndCodeAndDirection(
                trade.getUserId(), trade.getAccountId(), trade.getInstrumentType(), trade.getCode(), posDirection);

        if (isOpening) {
            Position position = existing.orElseGet(() -> {
                Position p = new Position();
                p.setUserId(trade.getUserId());
                p.setAccountId(trade.getAccountId());
                p.setInstrumentType(trade.getInstrumentType());
                p.setCode(trade.getCode());
                p.setName(trade.getName());
                p.setDirection(posDirection);
                p.setQuantity(BigDecimal.ZERO);
                p.setCostPrice(trade.getPrice());
                return p;
            });
            BigDecimal oldQty = position.getQuantity();
            BigDecimal newQty = oldQty.add(trade.getQuantity());
            // 加权平均成本 = (旧数量*旧成本 + 本次数量*本次价格) / 新数量
            BigDecimal weightedCost = oldQty.multiply(position.getCostPrice())
                    .add(trade.getQuantity().multiply(trade.getPrice()))
                    .divide(newQty, 4, RoundingMode.HALF_UP);
            position.setQuantity(newQty);
            position.setCostPrice(weightedCost);
            if (position.getCurrentPrice() == null) {
                position.setCurrentPrice(trade.getPrice());
            }
            if (trade.getMarginAmount() != null) {
                position.setMarginAmount(trade.getMarginAmount());
            }
            if (trade.getExpireDate() != null) {
                position.setExpireDate(trade.getExpireDate());
            }
            positionRepository.save(position);
        } else {
            existing.ifPresent(position -> {
                BigDecimal remaining = position.getQuantity().subtract(trade.getQuantity());
                if (remaining.compareTo(BigDecimal.ZERO) <= 0) {
                    positionRepository.delete(position);
                } else {
                    position.setQuantity(remaining);
                    positionRepository.save(position);
                }
            });
        }
    }

    public PositionSummaryResponse summary(Long userId, InstrumentType filterType) {
        List<Position> positions = filterType == null
                ? positionRepository.findByUserIdOrderByUpdatedAtDesc(userId)
                : positionRepository.findByUserIdAndInstrumentTypeOrderByUpdatedAtDesc(userId, filterType);

        BigDecimal totalMarketValue = BigDecimal.ZERO;
        BigDecimal totalFloatingPnl = BigDecimal.ZERO;
        BigDecimal totalCostValue = BigDecimal.ZERO;

        List<PositionDTO> dtoList = new ArrayList<>();
        for (Position p : positions) {
            BigDecimal current = p.getCurrentPrice() != null ? p.getCurrentPrice() : p.getCostPrice();
            BigDecimal marketValue = p.getQuantity().multiply(current);
            BigDecimal costValue = p.getQuantity().multiply(p.getCostPrice());
            BigDecimal floatingPnl = marketValue.subtract(costValue);
            // 卖方/义务仓（SHORT）收的是权利金，标的价格上涨对卖方不利，方向取反
            if (p.getDirection() == TradeDirection.SHORT && p.getInstrumentType() == InstrumentType.OPTION) {
                floatingPnl = floatingPnl.negate();
            }
            BigDecimal floatingPnlPct = costValue.compareTo(BigDecimal.ZERO) == 0
                    ? BigDecimal.ZERO
                    : floatingPnl.divide(costValue, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));

            totalMarketValue = totalMarketValue.add(marketValue);
            totalFloatingPnl = totalFloatingPnl.add(floatingPnl);
            totalCostValue = totalCostValue.add(costValue);

            dtoList.add(PositionDTO.builder()
                    .id(p.getId())
                    .instrumentType(p.getInstrumentType().name())
                    .code(p.getCode())
                    .name(p.getName())
                    .direction(p.getDirection().name())
                    .directionLabel(directionDisplayLabel(p.getInstrumentType(), p.getDirection()))
                    .quantity(p.getQuantity())
                    .costPrice(p.getCostPrice())
                    .currentPrice(current)
                    .marginAmount(p.getMarginAmount())
                    .expireDate(p.getExpireDate())
                    .daysToExpire(p.getExpireDate() == null ? null
                            : (int) java.time.temporal.ChronoUnit.DAYS.between(LocalDate.now(), p.getExpireDate()))
                    .marketValue(marketValue)
                    .floatingPnl(floatingPnl)
                    .floatingPnlPct(floatingPnlPct)
                    .weightPct(null) // 二次遍历后回填，见下方
                    .build());
        }

        // 用市值总和回填每笔持仓的占比权重（对应原型里持仓卡片的进度条 / 首页资产分布）
        BigDecimal finalTotal = totalMarketValue;
        List<PositionDTO> withWeights = new ArrayList<>();
        for (PositionDTO d : dtoList) {
            BigDecimal weight = finalTotal.compareTo(BigDecimal.ZERO) == 0
                    ? BigDecimal.ZERO
                    : d.getMarketValue().divide(finalTotal, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));
            withWeights.add(PositionDTO.builder()
                    .id(d.getId()).instrumentType(d.getInstrumentType()).code(d.getCode()).name(d.getName())
                    .direction(d.getDirection()).directionLabel(d.getDirectionLabel()).quantity(d.getQuantity())
                    .costPrice(d.getCostPrice()).currentPrice(d.getCurrentPrice()).marginAmount(d.getMarginAmount())
                    .expireDate(d.getExpireDate()).daysToExpire(d.getDaysToExpire()).marketValue(d.getMarketValue())
                    .floatingPnl(d.getFloatingPnl()).floatingPnlPct(d.getFloatingPnlPct())
                    .weightPct(weight.setScale(0, RoundingMode.HALF_UP))
                    .build());
        }

        BigDecimal availableCash = accountRepository.findByUserIdOrderByCreatedAtAsc(userId).stream()
                .map(a -> a.getAvailableCash())
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalMargin = positions.stream()
                .map(Position::getMarginAmount)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalAssets = availableCash.add(totalMarketValue);
        BigDecimal marginUsageRate = totalAssets.compareTo(BigDecimal.ZERO) == 0
                ? BigDecimal.ZERO
                : totalMargin.divide(totalAssets, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));

        BigDecimal floatingPnlPctTotal = totalCostValue.compareTo(BigDecimal.ZERO) == 0
                ? BigDecimal.ZERO
                : totalFloatingPnl.divide(totalCostValue, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));

        return PositionSummaryResponse.builder()
                .totalMarketValue(totalMarketValue)
                .floatingPnl(totalFloatingPnl)
                .floatingPnlPct(floatingPnlPctTotal)
                .availableCash(availableCash)
                .marginUsageRate(marginUsageRate)
                .items(withWeights)
                .build();
    }

    private String directionDisplayLabel(InstrumentType type, TradeDirection direction) {
        if (type == InstrumentType.STOCK) {
            return "持有";
        }
        return direction == TradeDirection.LONG ? "多" : "空";
    }

    public int countPositions(Long userId) {
        return positionRepository.findByUserIdOrderByUpdatedAtDesc(userId).size();
    }
}
