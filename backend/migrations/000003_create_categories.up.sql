CREATE TABLE categories (
    id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '分类ID',
    user_id    BIGINT UNSIGNED NOT NULL COMMENT '所属用户ID',
    name       VARCHAR(50)     NOT NULL COMMENT '分类名称, 如餐饮/工资',
    type       VARCHAR(10)     NOT NULL COMMENT '分类方向: income|expense',
    is_system  TINYINT         NOT NULL DEFAULT 0 COMMENT '是否系统预置: 1=系统预置不可删除, 0=用户自建',
    is_active  TINYINT         NOT NULL DEFAULT 1 COMMENT '是否启用: 1=启用, 0=停用',
    created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
    UNIQUE KEY uk_user_type_name (user_id, type, name),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='分类表';

