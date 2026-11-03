-- ============================================================
-- 复利 · 投资交易日志  示例数据（对应高保真原型页面里的展示数据）
-- 在执行完 schema.sql 建好库表之后，按需手动执行本文件——不是必须的，
-- 只是方便你联调时数据库里有点看得懂的数据，而不是空表。
-- ============================================================

USE `invest`;

INSERT INTO `sys_user` (id, username, password_hash, nickname) VALUES
  (1, 'frank', '$2a$10$placeholderplaceholderplaceholderplaceholderplaceh', 'Frank');

INSERT INTO `account` (id, user_id, name, broker, account_type, currency, available_cash) VALUES
  (1, 1, '招商证券-普通账户', '招商证券', 'STOCK', 'CNY', 183220.00),
  (2, 1, '中信期货账户', '中信期货', 'FUTURE', 'CNY', 96000.00),
  (3, 1, '华泰期权账户', '华泰证券', 'OPTION', 'CNY', 42000.00);

INSERT INTO `tag` (id, user_id, name) VALUES
  (1, 1, '波段'), (2, 1, '趋势'), (3, 1, '情绪化');

INSERT INTO `trade` (account_id, user_id, instrument_type, code, name, direction, quantity, price, close_price, strike_price, expire_date, margin_amount, leverage, fee, pnl_amount, pnl_pct, trade_time, note) VALUES
  (1, 1, 'STOCK', '600519', '贵州茅台', 'BUY', 100, 1680.5, NULL, NULL, NULL, NULL, NULL, 5.04, 2340.0, 1.41, '2026-09-12 09:31:00', '首次建仓，趋势确认后加仓'),
  (1, 1, 'STOCK', '300750', '宁德时代', 'SELL', 200, 168.2, NULL, NULL, NULL, NULL, NULL, 6.73, -890.5, -2.58, '2026-09-12 13:47:00', '跌破关键支撑位止损'),
  (2, 1, 'FUTURE', 'IF2410', '沪深300股指', 'LONG', 2, 3856.2, NULL, NULL, '2026-10-18', 185000.0, 8.3, 30.0, 4200.0, 2.24, '2026-09-12 10:05:00', '早盘突破后追多'),
  (3, 1, 'OPTION', '50ETF购12月3800', '50ETF购12月3800', 'BUY_CALL', 5, 0.0856, NULL, 3.8, '2026-12-25', NULL, NULL, 4.28, 1280.0, 42.7, '2026-09-11 14:20:00', ''),
  (1, 1, 'STOCK', '002594', '比亚迪', 'BUY', 50, 248.6, NULL, NULL, NULL, NULL, NULL, 3.73, 560.0, 4.51, '2026-09-11 09:45:00', ''),
  (2, 1, 'FUTURE', 'RB2501', '螺纹钢', 'SHORT', 3, 3420, NULL, NULL, '2027-01-15', 42000.0, 7.3, 18.0, -1020.0, -2.98, '2026-09-11 11:02:00', ''),
  (3, 1, 'OPTION', '300ETF沽1月4.0', '300ETF沽1月4.0', 'SELL_PUT', 10, 0.0432, NULL, 4.0, '2027-01-22', NULL, NULL, 4.32, 860.0, 19.9, '2026-09-10 10:30:00', ''),
  (1, 1, 'STOCK', '000858', '五粮液', 'SELL', 80, 152.3, NULL, NULL, NULL, NULL, NULL, 3.66, 1890.4, 15.5, '2026-09-10 14:52:00', ''),
  (2, 1, 'FUTURE', 'CU2411', '沪铜', 'LONG', 1, 73450, 72100, NULL, '2026-11-18', 36700.0, 6.6, 20.0, 3150.0, 4.42, '2026-09-10 15:10:00', '已平多'),
  (3, 1, 'OPTION', '50ETF沽12月3600', '50ETF沽12月3600', 'BUY_PUT', 8, 0.0215, NULL, 3.6, '2026-12-25', NULL, NULL, 3.44, -420.0, -24.9, '2026-09-09 09:52:00', '');

INSERT INTO `trade_position` (account_id, user_id, instrument_type, code, name, direction, quantity, cost_price, current_price, margin_amount, expire_date) VALUES
  (1, 1, 'STOCK', '600519', '贵州茅台', 'LONG', 300, 1620.3, 1680.5, NULL, NULL),
  (1, 1, 'STOCK', '300750', '宁德时代', 'LONG', 500, 172.8, 168.2, NULL, NULL),
  (1, 1, 'STOCK', '002594', '比亚迪', 'LONG', 200, 235.4, 248.6, NULL, NULL),
  (1, 1, 'STOCK', '000858', '五粮液', 'LONG', 320, 148.9, 152.3, NULL, NULL),
  (2, 1, 'FUTURE', 'IF2410', '沪深300股指', 'LONG', 2, 3820.4, 3856.2, 185000.0, '2026-10-18'),
  (2, 1, 'FUTURE', 'RB2501', '螺纹钢', 'SHORT', 3, 3465, 3420, 42000.0, '2027-01-15');

-- 30 天资金快照（对应首页/分析页的资金曲线），从 30 天前到今天，总资产逐步上涨到示例值。
-- 用存储过程/循环生成太重，这里直接给出一段递增序列，日期用 CURDATE() 相对偏移，
-- 保证不管你什么时候执行这份脚本，日期都是"最近 30 天"。
INSERT INTO `daily_equity_snapshot` (user_id, snap_date, total_assets, available_cash, position_value)
SELECT 1,
       DATE_SUB(CURDATE(), INTERVAL n DAY),
       1150000.00 + (29 - n) * 4700.00 + IF(n % 5 = 0, -3200, 0),
       183220.00 + (29 - n) * 30.00,
       (1150000.00 + (29 - n) * 4700.00 + IF(n % 5 = 0, -3200, 0)) - (183220.00 + (29 - n) * 30.00)
FROM (
  SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
  UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9
  UNION SELECT 10 UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14
  UNION SELECT 15 UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19
  UNION SELECT 20 UNION SELECT 21 UNION SELECT 22 UNION SELECT 23 UNION SELECT 24
  UNION SELECT 25 UNION SELECT 26 UNION SELECT 27 UNION SELECT 28 UNION SELECT 29
) AS days
ORDER BY n DESC;
