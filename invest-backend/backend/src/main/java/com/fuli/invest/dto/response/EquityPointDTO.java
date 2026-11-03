package com.fuli.invest.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class EquityPointDTO {
    private String date;       // yyyy-MM-dd
    private BigDecimal value;  // 当日总资产
}
