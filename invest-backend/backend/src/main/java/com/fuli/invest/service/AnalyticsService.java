package com.fuli.invest.service;

import com.fuli.invest.dto.response.*;
import com.fuli.invest.entity.DailyEquitySnapshot;
import com.fuli.invest.entity.InstrumentType;
import com.fuli.invest.entity.Trade;
import com.fuli.invest.entity.TradeDirection;
import com.fuli.invest.repository.DailyEquitySnapshotRepository;
import com.fuli.invest.repository.TradeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AnalyticsService {

    private final TradeRepository tradeRepository;
    private final DailyEquitySnapshotRepository snapshotRepository;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ISO_LOCAL_DATE;

    public AnalyticsSummaryResponse summary(Long userId, String range) {
        LocalDate today = LocalDate.now();
        LocalDate from = switch (range == null ? "year" : range) {
            case "month" -> today.minusMonths(1);
            case "quarter" -> today.minusMonths(3);
            case "year" -> today.minusYears(1);
            default -> today.minusYears(5); // "all"
        };
        LocalDateTime fromTime = from.atStartOfDay();
        LocalDateTime toTime = today.plusDays(1).atStartOfDay();

        List<Trade> trades = tradeRepository.findByUserIdAndTradeTimeBetweenOrderByTradeTimeAsc(userId, fromTime, toTime);
        List<Trade> closedTrades = trades.stream().filter(t -> t.getPnlAmount() != null).collect(Collectors.toList());

        BigDecimal totalPnl = closedTrades.stream().map(Trade::getPnlAmount).reduce(BigDecimal.ZERO, BigDecimal::add);

        long winCount = closedTrades.stream().filter(t -> t.getPnlAmount().compareTo(BigDecimal.ZERO) > 0).count();
        BigDecimal winRate = closedTrades.isEmpty()
                ? BigDecimal.ZERO
                : BigDecimal.valueOf(winCount).divide(BigDecimal.valueOf(closedTrades.size()), 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100)).setScale(1, RoundingMode.HALF_UP);

        BigDecimal avgWin = average(closedTrades.stream().map(Trade::getPnlAmount)
                .filter(p -> p.compareTo(BigDecimal.ZERO) > 0).collect(Collectors.toList()));
        BigDecimal avgLossAbs = average(closedTrades.stream().map(Trade::getPnlAmount)
                .filter(p -> p.compareTo(BigDecimal.ZERO) < 0).map(BigDecimal::abs).collect(Collectors.toList()));
        BigDecimal profitFactor = avgLossAbs.compareTo(BigDecimal.ZERO) == 0
                ? BigDecimal.ZERO
                : avgWin.divide(avgLossAbs, 2, RoundingMode.HALF_UP);

        List<DailyEquitySnapshot> snapshots =
                snapshotRepository.findByUserIdAndSnapDateBetweenOrderBySnapDateAsc(userId, from, today);
        List<EquityPointDTO> equityCurve = snapshots.stream()
                .map(s -> new EquityPointDTO(s.getSnapDate().format(DATE_FMT), s.getTotalAssets()))
                .collect(Collectors.toList());
        BigDecimal maxDrawdownPct = maxDrawdownPct(snapshots);

        List<ContributionDTO> contribution = contributionByType(closedTrades);
        List<MonthlyPnlDTO> monthlyPnl = monthlyPnl(closedTrades);
        BigDecimal avgHoldingDays = averageHoldingDays(trades);

        return AnalyticsSummaryResponse.builder()
                .totalPnl(totalPnl)
                .winRate(winRate)
                .profitFactor(profitFactor)
                .maxDrawdownPct(maxDrawdownPct)
                .tradeCount(trades.size())
                .avgHoldingDays(avgHoldingDays)
                .equityCurve(equityCurve)
                .contribution(contribution)
                .monthlyPnl(monthlyPnl)
                .build();
    }

    private BigDecimal average(List<BigDecimal> values) {
        if (values.isEmpty()) {
            return BigDecimal.ZERO;
        }
        BigDecimal sum = values.stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        return sum.divide(BigDecimal.valueOf(values.size()), 2, RoundingMode.HALF_UP);
    }

    /** 基于每日资金快照序列计算区间最大回撤百分比（返回负数，如 -8.4）。 */
    private BigDecimal maxDrawdownPct(List<DailyEquitySnapshot> snapshots) {
        BigDecimal peak = null;
        BigDecimal worstDrawdown = BigDecimal.ZERO;
        for (DailyEquitySnapshot s : snapshots) {
            if (peak == null || s.getTotalAssets().compareTo(peak) > 0) {
                peak = s.getTotalAssets();
            }
            if (peak.compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal drawdown = s.getTotalAssets().subtract(peak)
                        .divide(peak, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));
                if (drawdown.compareTo(worstDrawdown) < 0) {
                    worstDrawdown = drawdown;
                }
            }
        }
        return worstDrawdown.setScale(1, RoundingMode.HALF_UP);
    }

    private List<ContributionDTO> contributionByType(List<Trade> closedTrades) {
        Map<InstrumentType, BigDecimal> byType = closedTrades.stream().collect(Collectors.groupingBy(
                Trade::getInstrumentType,
                Collectors.reducing(BigDecimal.ZERO, Trade::getPnlAmount, BigDecimal::add)));
        BigDecimal maxAbs = byType.values().stream().map(BigDecimal::abs).max(Comparator.naturalOrder())
                .orElse(BigDecimal.ONE);
        if (maxAbs.compareTo(BigDecimal.ZERO) == 0) {
            maxAbs = BigDecimal.ONE;
        }
        BigDecimal finalMaxAbs = maxAbs;
        return List.of(InstrumentType.STOCK, InstrumentType.FUTURE, InstrumentType.OPTION).stream()
                .map(t -> {
                    BigDecimal v = byType.getOrDefault(t, BigDecimal.ZERO);
                    BigDecimal pct = v.abs().divide(finalMaxAbs, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));
                    return new ContributionDTO(t.name(), labelOf(t), v, pct.setScale(0, RoundingMode.HALF_UP));
                })
                .collect(Collectors.toList());
    }

    private List<MonthlyPnlDTO> monthlyPnl(List<Trade> closedTrades) {
        Map<String, BigDecimal> byMonth = new LinkedHashMap<>();
        LocalDate cursor = LocalDate.now().minusMonths(7).withDayOfMonth(1);
        for (int i = 0; i < 8; i++) {
            byMonth.put(cursor.getMonthValue() + "月", BigDecimal.ZERO);
            cursor = cursor.plusMonths(1);
        }
        for (Trade t : closedTrades) {
            String key = t.getTradeTime().getMonthValue() + "月";
            if (byMonth.containsKey(key)) {
                byMonth.put(key, byMonth.get(key).add(t.getPnlAmount()));
            }
        }
        return byMonth.entrySet().stream().map(e -> new MonthlyPnlDTO(e.getKey(), e.getValue()))
                .collect(Collectors.toList());
    }

    /**
     * 平均持仓天数（简化版 FIFO 撮合）：按 代码+品种 分组，开仓动作入队，平仓动作按 FIFO
     * 依次消耗队列里最早的开仓批次，用"平仓日 - 开仓日"乘以匹配数量做加权平均。
     * 局限：不区分账户，且期权买卖没有显式开平仓标记（见 PositionService 类注释），
     * 这里期权按 BUY_*=开仓 / SELL_*=开仓 处理，SELL_* / CLOSE_* 才会被当成平仓来匹配——
     * 也就是说同一账户下先 BUY_CALL 后 SELL_CALL 才会被计入持仓天数统计。
     */
    private BigDecimal averageHoldingDays(List<Trade> trades) {
        record Lot(LocalDate openDate, BigDecimal qty) {
        }

        Map<String, Deque<Lot>> openLots = new HashMap<>();
        BigDecimal totalWeightedDays = BigDecimal.ZERO;
        BigDecimal totalMatchedQty = BigDecimal.ZERO;

        List<Trade> sorted = trades.stream()
                .sorted(Comparator.comparing(Trade::getTradeTime))
                .collect(Collectors.toList());

        for (Trade t : sorted) {
            String key = t.getInstrumentType() + "|" + t.getCode() + "|" + TradeDirectionRules.positionDirection(t.getDirection());
            Deque<Lot> queue = openLots.computeIfAbsent(key, k -> new ArrayDeque<>());
            if (TradeDirectionRules.isOpening(t.getDirection())) {
                queue.addLast(new Lot(t.getTradeTime().toLocalDate(), t.getQuantity()));
            } else {
                BigDecimal remainingToClose = t.getQuantity();
                while (remainingToClose.compareTo(BigDecimal.ZERO) > 0 && !queue.isEmpty()) {
                    Lot lot = queue.peekFirst();
                    BigDecimal matched = lot.qty().min(remainingToClose);
                    long days = ChronoUnit.DAYS.between(lot.openDate(), t.getTradeTime().toLocalDate());
                    totalWeightedDays = totalWeightedDays.add(matched.multiply(BigDecimal.valueOf(Math.max(days, 0))));
                    totalMatchedQty = totalMatchedQty.add(matched);
                    remainingToClose = remainingToClose.subtract(matched);
                    BigDecimal lotRemaining = lot.qty().subtract(matched);
                    queue.pollFirst();
                    if (lotRemaining.compareTo(BigDecimal.ZERO) > 0) {
                        queue.addFirst(new Lot(lot.openDate(), lotRemaining));
                    }
                }
            }
        }

        return totalMatchedQty.compareTo(BigDecimal.ZERO) == 0
                ? BigDecimal.ZERO
                : totalWeightedDays.divide(totalMatchedQty, 1, RoundingMode.HALF_UP);
    }

    private String labelOf(InstrumentType type) {
        return switch (type) {
            case STOCK -> "股票";
            case FUTURE -> "期货";
            case OPTION -> "期权";
        };
    }
}
