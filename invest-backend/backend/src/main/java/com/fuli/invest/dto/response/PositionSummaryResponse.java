package com.fuli.invest.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Builder
public class PositionSummaryResponse {
    private BigDecimal totalMarketValue;
    private BigDecimal floatingPnl;
    private BigDecimal floatingPnlPct;
    private BigDecimal availableCash;
    private BigDecimal marginUsageRate;
    private List<PositionDTO> items;
}
