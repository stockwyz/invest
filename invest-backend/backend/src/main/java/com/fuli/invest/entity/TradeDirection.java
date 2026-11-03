package com.fuli.invest.entity;

/**
 * 交易方向。不同品种取不同子集，前端"记一笔交易"表单按 instrumentType 切换可选项：
 * 股票：BUY / SELL
 * 期货：LONG / SHORT / CLOSE_LONG / CLOSE_SHORT
 * 期权：BUY_CALL / SELL_CALL / BUY_PUT / SELL_PUT
 */
public enum TradeDirection {
    BUY,
    SELL,
    LONG,
    SHORT,
    CLOSE_LONG,
    CLOSE_SHORT,
    BUY_CALL,
    SELL_CALL,
    BUY_PUT,
    SELL_PUT;

    /** 是否为"买入/开多/权利方买入"一类方向 —— 决定前端红/绿配色（红=买入方向，绿=卖出方向，遵循 A 股习惯）。 */
    public boolean isBuySide() {
        return this == BUY || this == LONG || this == BUY_CALL || this == BUY_PUT || this == CLOSE_SHORT;
    }

    /** 中文展示名，供 DTO 直接使用，避免前端再维护一份映射表。 */
    public String label() {
        return switch (this) {
            case BUY -> "买入";
            case SELL -> "卖出";
            case LONG -> "开多";
            case SHORT -> "开空";
            case CLOSE_LONG -> "平多";
            case CLOSE_SHORT -> "平空";
            case BUY_CALL -> "买入 Call";
            case SELL_CALL -> "卖出 Call";
            case BUY_PUT -> "买入 Put";
            case SELL_PUT -> "卖出 Put";
        };
    }
}
