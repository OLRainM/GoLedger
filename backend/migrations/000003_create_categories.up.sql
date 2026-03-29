CREATE TABLE categories (
    id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id    BIGINT UNSIGNED NOT NULL,
    name       VARCHAR(50)     NOT NULL,
    type       VARCHAR(10)     NOT NULL COMMENT 'income|expense',
    is_system  TINYINT         NOT NULL DEFAULT 0 COMMENT '1=系统预置, 不可删除',
    is_active  TINYINT         NOT NULL DEFAULT 1,
    created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_type_name (user_id, type, name),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

