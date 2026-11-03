package com.fuli.invest.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Builder
public class AnalyticsSummaryResponse {
    private BigDecimal totalPnl;
    private BigDecimal winRate;         // 0-100
    private BigDecimal profitFactor;    // 平均盈利 / 平均亏损
    private BigDecimal maxDrawdownPct;  // 负数，如 -8.4
    private int tradeCount;
    private BigDecimal avgHoldingDays;
    private List<EquityPointDTO> equityCurve;
    private List<ContributionDTO> contribution;
    private List<MonthlyPnlDTO> monthlyPnl;
}
