CREATE TABLE transactions (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED NOT NULL,
    account_id      BIGINT UNSIGNED NOT NULL,
    category_id     BIGINT UNSIGNED NOT NULL,
    type            VARCHAR(10)     NOT NULL COMMENT 'income|expense',
    amount          BIGINT          NOT NULL COMMENT '单位: 分',
    note            VARCHAR(200)    NOT NULL DEFAULT '',
    transaction_at  DATETIME        NOT NULL COMMENT '用户选择的记账时间',
    source_type     VARCHAR(10)     NOT NULL DEFAULT 'manual' COMMENT 'manual|ocr (V1 只有 manual)',
    version         INT UNSIGNED    NOT NULL DEFAULT 1,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME        DEFAULT NULL,
    INDEX idx_user_time (user_id, transaction_at),
    INDEX idx_user_account (user_id, account_id),
    INDEX idx_user_category (user_id, category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

