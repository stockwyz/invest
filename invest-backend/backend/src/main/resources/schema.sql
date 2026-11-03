-- 本地开发用（H2，MySQL 兼容模式）。生产环境请使用 /sql/schema.sql 在 MySQL 中建库建表，
-- 并将 spring.sql.init.mode 设为 never（见 application.yml 的 mysql profile）。
-- 两份 schema 表结构保持一致，仅去掉了 H2 不支持/不需要的 MySQL 专属语法
-- （ENGINE/CHARSET/UNSIGNED/内联 COMMENT/ON UPDATE CURRENT_TIMESTAMP，updated_at 改由 JPA 维护）。

CREATE TABLE IF NOT EXISTS sys_user (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(64)  NOT NULL UNIQUE,
  password_hash VARCHAR(128) NOT NULL,
  nickname      VARCHAR(64),
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS account (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id        BIGINT NOT NULL REFERENCES sys_user(id),
  name           VARCHAR(64) NOT NULL,
  broker         VARCHAR(64),
  account_type   VARCHAR(16) NOT NULL,
  currency       VARCHAR(8) NOT NULL DEFAULT 'CNY',
  available_cash DECIMAL(18,2) NOT NULL DEFAULT 0,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_account_user ON account(user_id);

CREATE TABLE IF NOT EXISTS tag (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES sys_user(id),
  name       VARCHAR(32) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_tag_user_name UNIQUE (user_id, name)
);

CREATE TABLE IF NOT EXISTS trade (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT NOT NULL REFERENCES sys_user(id),
  account_id      BIGINT REFERENCES account(id),
  instrument_type VARCHAR(8)  NOT NULL,
  code            VARCHAR(32) NOT NULL,
  name            VARCHAR(64) NOT NULL,
  direction       VARCHAR(16) NOT NULL,
  quantity        DECIMAL(18,4) NOT NULL,
  price           DECIMAL(18,4) NOT NULL,
  close_price     DECIMAL(18,4),
  strike_price    DECIMAL(18,4),
  expire_date     DATE,
  margin_amount   DECIMAL(18,2),
  leverage        DECIMAL(8,2),
  fee             DECIMAL(18,2) NOT NULL DEFAULT 0,
  pnl_amount      DECIMAL(18,2),
  pnl_pct         DECIMAL(8,4),
  trade_time      DATETIME NOT NULL,
  note            CLOB,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_trade_user_time ON trade(user_id, trade_time);
CREATE INDEX IF NOT EXISTS idx_trade_user_type ON trade(user_id, instrument_type);

CREATE TABLE IF NOT EXISTS trade_tag (
  trade_id BIGINT NOT NULL REFERENCES trade(id),
  tag_id   BIGINT NOT NULL REFERENCES tag(id),
  PRIMARY KEY (trade_id, tag_id)
);

CREATE TABLE IF NOT EXISTS trade_position (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT NOT NULL REFERENCES sys_user(id),
  account_id      BIGINT REFERENCES account(id),
  instrument_type VARCHAR(8)  NOT NULL,
  code            VARCHAR(32) NOT NULL,
  name            VARCHAR(64) NOT NULL,
  direction       VARCHAR(16) NOT NULL,
  quantity        DECIMAL(18,4) NOT NULL,
  cost_price      DECIMAL(18,4) NOT NULL,
  current_price   DECIMAL(18,4),
  margin_amount   DECIMAL(18,2),
  expire_date     DATE,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_position_unique UNIQUE (user_id, account_id, instrument_type, code, direction)
);
CREATE INDEX IF NOT EXISTS idx_position_user_type ON trade_position(user_id, instrument_type);

CREATE TABLE IF NOT EXISTS daily_equity_snapshot (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id         BIGINT NOT NULL,
  snap_date       DATE NOT NULL,
  total_assets    DECIMAL(18,2) NOT NULL,
  available_cash  DECIMAL(18,2) NOT NULL,
  position_value  DECIMAL(18,2) NOT NULL,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_snapshot_user_date UNIQUE (user_id, snap_date)
);
