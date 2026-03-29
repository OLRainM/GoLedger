CREATE TABLE transactions (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '流水ID',
    user_id         BIGINT UNSIGNED NOT NULL COMMENT '所属用户ID',
    account_id      BIGINT UNSIGNED NOT NULL COMMENT '关联账户ID',
    category_id     BIGINT UNSIGNED NOT NULL COMMENT '关联分类ID',
    type            VARCHAR(10)     NOT NULL COMMENT '流水方向: income|expense',
    amount          BIGINT          NOT NULL COMMENT '金额, 单位: 分, 始终为正数',
    note            VARCHAR(200)    NOT NULL DEFAULT '' COMMENT '备注信息',
    transaction_at  DATETIME        NOT NULL COMMENT '用户选择的记账时间',
    source_type     VARCHAR(10)     NOT NULL DEFAULT 'manual' COMMENT '来源类型: manual|ocr (V1 只有 manual)',
    version         INT UNSIGNED    NOT NULL DEFAULT 1 COMMENT '乐观锁版本号, 每次编辑+1',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
    deleted_at      DATETIME        DEFAULT NULL COMMENT '软删除时间, NULL=未删除',
    INDEX idx_user_time (user_id, transaction_at),
    INDEX idx_user_account (user_id, account_id),
    INDEX idx_user_category (user_id, category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流水表';

