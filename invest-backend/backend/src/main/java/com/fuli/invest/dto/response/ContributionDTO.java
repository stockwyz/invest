package com.fuli.invest.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class ContributionDTO {
    private String type;
    private String label;
    private BigDecimal value;   // 该品种盈亏合计
    private BigDecimal pct;     // 相对最大绝对值的占比，用于横向条形图长度
}
