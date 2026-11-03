package com.fuli.invest.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Builder
public class DashboardSummaryResponse {
    private BigDecimal totalAssets;
    private BigDecimal todayPnl;
    private BigDecimal todayPct;
    private String period;                     // day/week/month/year/all，回显当前选中周期
    private List<EquityPointDTO> equityCurve;
    private List<AllocationDTO> allocation;     // 股票/期货/期权占比
    private BigDecimal winRateWeek;             // 本周胜率 0-100
    private int positionCount;                  // 持仓数
    private BigDecimal marginUsageRate;         // 保证金占用 0-100
    private List<TradeDTO> recentTrades;
}
