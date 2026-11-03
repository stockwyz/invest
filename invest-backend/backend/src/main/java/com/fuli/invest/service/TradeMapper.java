package com.fuli.invest.service;

import com.fuli.invest.dto.response.TradeDTO;
import com.fuli.invest.entity.Tag;
import com.fuli.invest.entity.Trade;

import java.util.List;
import java.util.stream.Collectors;

/** Trade 实体 -> TradeDTO 的映射，独立出来给 TradeService / DashboardService 共用。 */
public final class TradeMapper {

    private TradeMapper() {
    }

    public static TradeDTO toDto(Trade trade, String accountName) {
        List<String> tagNames = trade.getTags().stream().map(Tag::getName).collect(Collectors.toList());
        return TradeDTO.builder()
                .id(trade.getId())
                .accountId(trade.getAccountId())
                .accountName(accountName)
                .instrumentType(trade.getInstrumentType().name())
                .code(trade.getCode())
                .name(trade.getName())
                .direction(trade.getDirection().name())
                .directionLabel(trade.getDirection().label())
                .buySide(trade.getDirection().isBuySide())
                .quantity(trade.getQuantity())
                .price(trade.getPrice())
                .closePrice(trade.getClosePrice())
                .strikePrice(trade.getStrikePrice())
                .expireDate(trade.getExpireDate())
                .marginAmount(trade.getMarginAmount())
                .leverage(trade.getLeverage())
                .fee(trade.getFee())
                .pnlAmount(trade.getPnlAmount())
                .pnlPct(trade.getPnlPct())
                .tradeTime(trade.getTradeTime())
                .note(trade.getNote())
                .tags(tagNames)
                .build();
    }
}
