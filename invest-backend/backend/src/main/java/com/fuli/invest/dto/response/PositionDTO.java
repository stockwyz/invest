package com.fuli.invest.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Builder
public class PositionDTO {
    private Long id;
    private String instrumentType;
    private String code;
    private String name;
    private String direction;
    private String directionLabel;
    private BigDecimal quantity;
    private BigDecimal costPrice;
    private BigDecimal currentPrice;
    private BigDecimal marginAmount;
    private LocalDate expireDate;
    private Integer daysToExpire;      // 到期倒计时（天），非期货/期权为 null
    private BigDecimal marketValue;    // 数量 * 现价（股票）或按合约估算的持仓市值
    private BigDecimal floatingPnl;
    private BigDecimal floatingPnlPct;
    private BigDecimal weightPct;      // 占该品种类别市值的占比，用于持仓页进度条
}
