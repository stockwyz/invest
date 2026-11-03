package com.fuli.invest.entity;

/** 资金账户类型。COMPOSITE 表示综合账户（同时可记录多品种）。 */
public enum AccountType {
    STOCK,
    FUTURE,
    OPTION,
    COMPOSITE
}
