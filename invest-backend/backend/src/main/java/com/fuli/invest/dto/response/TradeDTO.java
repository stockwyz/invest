package com.fuli.invest.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class TradeDTO {
    private Long id;
    private Long accountId;
    private String accountName;
    private String instrumentType;   // STOCK/FUTURE/OPTION
    private String code;
    private String name;
    private String direction;        // 枚举名，如 BUY / LONG / BUY_CALL
    private String directionLabel;   // 中文展示：买入 / 开多 / 买入 Call
    private boolean buySide;         // true=红色(买入方向) false=绿色(卖出方向)
    private BigDecimal quantity;
    private BigDecimal price;
    private BigDecimal closePrice;
    private BigDecimal strikePrice;
    private LocalDate expireDate;
    private BigDecimal marginAmount;
    private BigDecimal leverage;
    private BigDecimal fee;
    private BigDecimal pnlAmount;
    private BigDecimal pnlPct;
    private LocalDateTime tradeTime;
    private String note;
    private List<String> tags;
}
