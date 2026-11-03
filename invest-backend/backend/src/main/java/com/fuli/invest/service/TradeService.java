package com.fuli.invest.service;

import com.fuli.invest.common.BizException;
import com.fuli.invest.dto.request.TradeSaveRequest;
import com.fuli.invest.dto.response.PageResult;
import com.fuli.invest.dto.response.TradeDTO;
import com.fuli.invest.entity.Account;
import com.fuli.invest.entity.InstrumentType;
import com.fuli.invest.entity.Tag;
import com.fuli.invest.entity.Trade;
import com.fuli.invest.repository.AccountRepository;
import com.fuli.invest.repository.TagRepository;
import com.fuli.invest.repository.TradeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class TradeService {

    private final TradeRepository tradeRepository;
    private final AccountRepository accountRepository;
    private final TagRepository tagRepository;
    private final PositionService positionService;

    @Transactional
    public TradeDTO create(Long userId, TradeSaveRequest req) {
        Trade trade = new Trade();
        trade.setUserId(userId);
        applyRequest(trade, req);
        fillDerivedFields(trade);
        tradeRepository.save(trade);
        positionService.recomputeAll(userId);
        return TradeMapper.toDto(trade, accountName(trade.getAccountId()));
    }

    @Transactional
    public TradeDTO update(Long userId, Long tradeId, TradeSaveRequest req) {
        Trade trade = tradeRepository.findById(tradeId)
                .filter(t -> t.getUserId().equals(userId))
                .orElseThrow(() -> new BizException(40401, "交易记录不存在"));
        applyRequest(trade, req);
        fillDerivedFields(trade);
        tradeRepository.save(trade);
        positionService.recomputeAll(userId);
        return TradeMapper.toDto(trade, accountName(trade.getAccountId()));
    }

    @Transactional
    public void delete(Long userId, Long tradeId) {
        Trade trade = tradeRepository.findById(tradeId)
                .filter(t -> t.getUserId().equals(userId))
                .orElseThrow(() -> new BizException(40401, "交易记录不存在"));
        tradeRepository.delete(trade);
        positionService.recomputeAll(userId);
    }

    public TradeDTO get(Long userId, Long tradeId) {
        Trade trade = tradeRepository.findById(tradeId)
                .filter(t -> t.getUserId().equals(userId))
                .orElseThrow(() -> new BizException(40401, "交易记录不存在"));
        return TradeMapper.toDto(trade, accountName(trade.getAccountId()));
    }

    public PageResult<TradeDTO> list(Long userId, InstrumentType type, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "tradeTime"));
        Page<Trade> result = type == null
                ? tradeRepository.findByUserIdOrderByTradeTimeDesc(userId, pageable)
                : tradeRepository.findByUserIdAndInstrumentTypeOrderByTradeTimeDesc(userId, type, pageable);
        Page<TradeDTO> mapped = result.map(t -> TradeMapper.toDto(t, accountName(t.getAccountId())));
        return PageResult.of(mapped);
    }

    private void applyRequest(Trade trade, TradeSaveRequest req) {
        trade.setAccountId(req.getAccountId());
        trade.setInstrumentType(req.getInstrumentType());
        trade.setCode(req.getCode());
        trade.setName(req.getName());
        trade.setDirection(req.getDirection());
        trade.setQuantity(req.getQuantity());
        trade.setPrice(req.getPrice());
        trade.setClosePrice(req.getClosePrice());
        trade.setStrikePrice(req.getStrikePrice());
        trade.setExpireDate(req.getExpireDate());
        trade.setMarginAmount(req.getMarginAmount());
        trade.setFee(req.getFee() == null ? BigDecimal.ZERO : req.getFee());
        trade.setTradeTime(req.getTradeTime());
        trade.setNote(req.getNote());
        trade.setTags(resolveTags(trade.getUserId(), req.getTagNames()));
    }

    private Set<Tag> resolveTags(Long userId, List<String> tagNames) {
        Set<Tag> tags = new HashSet<>();
        if (tagNames == null) {
            return tags;
        }
        for (String name : tagNames) {
            if (name == null || name.isBlank()) {
                continue;
            }
            Tag tag = tagRepository.findByUserIdAndName(userId, name.trim())
                    .orElseGet(() -> {
                        Tag t = new Tag();
                        t.setUserId(userId);
                        t.setName(name.trim());
                        return tagRepository.save(t);
                    });
            tags.add(tag);
        }
        return tags;
    }

    /**
     * 自动计算：
     * - 期货杠杆 = 名义价值(数量*价格，简化未乘合约乘数) / 保证金
     * - 已平仓交易（填了 closePrice）自动算出该笔的盈亏金额与百分比，方向按买卖/多空/权利方义务方修正正负号
     * 用户如果直接在表单里手填了盈亏，这里不覆盖（MVP 暂不支持手填盈亏，统一自动算）。
     */
    private void fillDerivedFields(Trade trade) {
        if (trade.getInstrumentType() == InstrumentType.FUTURE
                && trade.getMarginAmount() != null
                && trade.getMarginAmount().compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal notional = trade.getQuantity().multiply(trade.getPrice());
            trade.setLeverage(notional.divide(trade.getMarginAmount(), 2, RoundingMode.HALF_UP));
        }

        if (trade.getClosePrice() != null) {
            BigDecimal diff = trade.getClosePrice().subtract(trade.getPrice());
            boolean buySide = trade.getDirection().isBuySide();
            BigDecimal directional = buySide ? diff : diff.negate();
            BigDecimal grossPnl = directional.multiply(trade.getQuantity());
            BigDecimal netPnl = grossPnl.subtract(trade.getFee());
            BigDecimal costBasis = trade.getPrice().multiply(trade.getQuantity());
            BigDecimal pnlPct = costBasis.compareTo(BigDecimal.ZERO) == 0
                    ? BigDecimal.ZERO
                    : netPnl.divide(costBasis, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));
            trade.setPnlAmount(netPnl.setScale(2, RoundingMode.HALF_UP));
            trade.setPnlPct(pnlPct.setScale(2, RoundingMode.HALF_UP));
        }
    }

    private String accountName(Long accountId) {
        if (accountId == null) {
            return null;
        }
        return accountRepository.findById(accountId).map(Account::getName).orElse(null);
    }
}
