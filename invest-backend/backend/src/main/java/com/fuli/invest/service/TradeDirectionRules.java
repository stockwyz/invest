package com.fuli.invest.service;

import com.fuli.invest.entity.TradeDirection;

/**
 * 交易方向 -> 持仓方向桶 / 开仓或平仓动作 的规则，PositionService 和 AnalyticsService 共用，
 * 避免两处各写一份容易漂移的映射逻辑。
 */
public final class TradeDirectionRules {

    private TradeDirectionRules() {
    }

    /** 落到持仓表的哪个方向桶：LONG=多头/买方，SHORT=空头/义务仓。 */
    public static TradeDirection positionDirection(TradeDirection direction) {
        return switch (direction) {
            case BUY, LONG, CLOSE_SHORT, BUY_CALL, BUY_PUT -> TradeDirection.LONG;
            case SELL, SHORT, CLOSE_LONG, SELL_CALL, SELL_PUT -> TradeDirection.SHORT;
        };
    }

    /** 是"新开/加仓"还是"减仓/平仓"。 */
    public static boolean isOpening(TradeDirection direction) {
        return switch (direction) {
            case BUY, LONG, SHORT, BUY_CALL, SELL_CALL, BUY_PUT, SELL_PUT -> true;
            case SELL, CLOSE_LONG, CLOSE_SHORT -> false;
        };
    }
}
