package com.fuli.invest.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class AllocationDTO {
    private String type;   // STOCK/FUTURE/OPTION
    private String label;  // 股票/期货/期权
    private BigDecimal pct; // 0-100
}
