CREATE TABLE accounts (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED NOT NULL,
    name            VARCHAR(50)     NOT NULL,
    type            VARCHAR(20)     NOT NULL COMMENT 'cash|bank_card|e_wallet|other',
    balance         BIGINT          NOT NULL DEFAULT 0 COMMENT '单位: 分',
    initial_balance BIGINT          NOT NULL DEFAULT 0 COMMENT '单位: 分',
    is_active       TINYINT         NOT NULL DEFAULT 1,
    version         INT UNSIGNED    NOT NULL DEFAULT 1,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

