-- ============================================================
-- 复利 · 投资交易日志  数据库结构（MySQL 8.0+ / utf8mb4）
-- 对应原型：首页仪表盘 / 交易记录 / 记一笔交易 / 持仓管理 / 数据分析
-- ============================================================

CREATE DATABASE IF NOT EXISTS `invest` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `invest`;

-- ------------------------------------------------------------
-- 用户表（MVP 阶段仅占位，未接入完整登录鉴权）
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sys_user` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username`      VARCHAR(64)  NOT NULL COMMENT '登录名',
  `password_hash` VARCHAR(128) NOT NULL COMMENT 'BCrypt 密码哈希',
  `nickname`      VARCHAR(64)  DEFAULT NULL COMMENT '昵称，首页问候语使用',
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- ------------------------------------------------------------
-- 资金账户表：对应"记一笔交易"表单里的"所属账户"选择
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `account` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`       BIGINT UNSIGNED NOT NULL,
  `name`          VARCHAR(64)  NOT NULL COMMENT '账户名称，如"招商证券-普通账户"',
  `broker`        VARCHAR(64)  DEFAULT NULL COMMENT '券商/期货公司名称',
  `account_type`  VARCHAR(16)  NOT NULL COMMENT 'STOCK/FUTURE/OPTION/COMPOSITE',
  `currency`      VARCHAR(8)   NOT NULL DEFAULT 'CNY',
  `available_cash`DECIMAL(18,2) NOT NULL DEFAULT 0 COMMENT '可用资金，用于首页/持仓页汇总',
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_account_user` (`user_id`),
  CONSTRAINT `fk_account_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资金账户表';

-- ------------------------------------------------------------
-- 标签表：交易记录/复盘用的自定义标签，如"波段""情绪化"
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tag` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT UNSIGNED NOT NULL,
  `name`       VARCHAR(32) NOT NULL,
  `created_at` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tag_user_name` (`user_id`, `name`),
  CONSTRAINT `fk_tag_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='标签表';

-- ------------------------------------------------------------
-- 交易记录表：核心表，覆盖股票/期货/期权三类字段（宽表设计）
-- instrument_type 决定哪些字段有效，具体见字段注释
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `trade` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`          BIGINT UNSIGNED NOT NULL,
  `account_id`       BIGINT UNSIGNED DEFAULT NULL,
  `instrument_type`  VARCHAR(8)   NOT NULL COMMENT 'STOCK/FUTURE/OPTION',
  `code`             VARCHAR(32)  NOT NULL COMMENT '代码，如 600519 / IF2410 / 50ETF购12月3800',
  `name`             VARCHAR(64)  NOT NULL COMMENT '名称，如 贵州茅台',
  `direction`        VARCHAR(16)  NOT NULL COMMENT 'BUY/SELL(股票) LONG/SHORT/CLOSE_LONG/CLOSE_SHORT(期货) BUY_CALL/SELL_CALL/BUY_PUT/SELL_PUT(期权)',
  `quantity`         DECIMAL(18,4) NOT NULL COMMENT '数量：股数/手数/张数',
  `price`            DECIMAL(18,4) NOT NULL COMMENT '成交价/开仓价/权利金',
  `close_price`      DECIMAL(18,4) DEFAULT NULL COMMENT '平仓价（已平仓时填写）',
  `strike_price`     DECIMAL(18,4) DEFAULT NULL COMMENT '行权价（期权专用）',
  `expire_date`      DATE          DEFAULT NULL COMMENT '到期日（期货/期权专用）',
  `margin_amount`    DECIMAL(18,2) DEFAULT NULL COMMENT '保证金占用（期货专用）',
  `leverage`         DECIMAL(8,2)  DEFAULT NULL COMMENT '杠杆倍数（期货，按合约价值/保证金自动计算）',
  `fee`              DECIMAL(18,2) NOT NULL DEFAULT 0 COMMENT '手续费/印花税/过户费合计',
  `pnl_amount`       DECIMAL(18,2) DEFAULT NULL COMMENT '该笔交易盈亏金额',
  `pnl_pct`          DECIMAL(8,4)  DEFAULT NULL COMMENT '该笔交易盈亏百分比',
  `trade_time`       DATETIME      NOT NULL COMMENT '成交时间',
  `note`             TEXT          DEFAULT NULL COMMENT '复盘笔记',
  `created_at`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_trade_user_time` (`user_id`, `trade_time`),
  KEY `idx_trade_user_type` (`user_id`, `instrument_type`),
  KEY `idx_trade_account` (`account_id`),
  CONSTRAINT `fk_trade_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`),
  CONSTRAINT `fk_trade_account` FOREIGN KEY (`account_id`) REFERENCES `account` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='交易记录表';

-- ------------------------------------------------------------
-- 交易-标签 关联表（多对多）
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `trade_tag` (
  `trade_id` BIGINT UNSIGNED NOT NULL,
  `tag_id`   BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`trade_id`, `tag_id`),
  CONSTRAINT `fk_tt_trade` FOREIGN KEY (`trade_id`) REFERENCES `trade` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tt_tag`   FOREIGN KEY (`tag_id`)   REFERENCES `tag` (`id`)   ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='交易与标签关联表';

-- ------------------------------------------------------------
-- 持仓表：由交易记录汇总/维护（服务层在每次新增、编辑、删除
-- 交易时按加权平均法重新计算），用于"持仓管理"页快速查询，
-- 避免每次都对全部历史交易做聚合运算。
-- current_price 由人工在持仓页更新，或后续接入行情接口后台刷新。
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `trade_position` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`          BIGINT UNSIGNED NOT NULL,
  `account_id`       BIGINT UNSIGNED DEFAULT NULL,
  `instrument_type`  VARCHAR(8)    NOT NULL COMMENT 'STOCK/FUTURE/OPTION',
  `code`             VARCHAR(32)   NOT NULL,
  `name`             VARCHAR(64)   NOT NULL,
  `direction`        VARCHAR(16)   NOT NULL COMMENT '持仓方向，股票恒为 LONG，期货/期权为 LONG/SHORT',
  `quantity`         DECIMAL(18,4) NOT NULL COMMENT '当前持仓数量（股/手/张）',
  `cost_price`       DECIMAL(18,4) NOT NULL COMMENT '加权平均成本价/权利金成本',
  `current_price`    DECIMAL(18,4) DEFAULT NULL COMMENT '最新价，人工维护或行情接口刷新',
  `margin_amount`    DECIMAL(18,2) DEFAULT NULL COMMENT '保证金占用（期货）',
  `expire_date`      DATE          DEFAULT NULL COMMENT '到期日（期货/期权）',
  `updated_at`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_position_unique` (`user_id`, `account_id`, `instrument_type`, `code`, `direction`),
  KEY `idx_position_user_type` (`user_id`, `instrument_type`),
  CONSTRAINT `fk_position_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='当前持仓表（由交易记录聚合维护）';

-- ------------------------------------------------------------
-- 每日资金快照：驱动首页/分析页的资金曲线。
-- 由每日定时任务（见 EquitySnapshotJob）在收盘后写入一条。
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `daily_equity_snapshot` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`        BIGINT UNSIGNED NOT NULL,
  `snap_date`      DATE          NOT NULL,
  `total_assets`   DECIMAL(18,2) NOT NULL COMMENT '总资产 = 可用资金 + 持仓市值',
  `available_cash` DECIMAL(18,2) NOT NULL,
  `position_value` DECIMAL(18,2) NOT NULL,
  `created_at`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_snapshot_user_date` (`user_id`, `snap_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='每日资金快照（资金曲线数据源）';
