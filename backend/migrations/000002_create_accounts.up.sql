CREATE TABLE accounts (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '账户ID',
    user_id         BIGINT UNSIGNED NOT NULL COMMENT '所属用户ID',
    name            VARCHAR(50)     NOT NULL COMMENT '账户名称, 如现金/招商银行卡',
    type            VARCHAR(20)     NOT NULL COMMENT '账户类型: cash|bank_card|e_wallet|other',
    balance         BIGINT          NOT NULL DEFAULT 0 COMMENT '当前余额, 单位: 分',
    initial_balance BIGINT          NOT NULL DEFAULT 0 COMMENT '初始余额, 单位: 分',
    is_active       TINYINT         NOT NULL DEFAULT 1 COMMENT '是否启用: 1=启用, 0=停用',
    version         INT UNSIGNED    NOT NULL DEFAULT 1 COMMENT '乐观锁版本号, 每次余额变更+1',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='账户表';

