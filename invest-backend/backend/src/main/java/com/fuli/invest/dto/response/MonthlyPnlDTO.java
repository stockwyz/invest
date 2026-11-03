package com.fuli.invest.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class MonthlyPnlDTO {
    private String month;      // "2月"
    private BigDecimal value;
}
