# GoLedger V1 API 接口文档

> 基础地址: `http://115.190.125.177:8080`
>
> 所有请求和响应均使用 JSON 格式. 需要鉴权的接口必须在请求头中携带 `Authorization: Bearer {token}`.
>
> 金额字段单位统一为**分** (1 元 = 100 分), 类型为整数 (int64). 前端展示时除以 100.

---

## 通用约定

### 统一响应结构

每个接口都返回以下 JSON 结构, 前端只需判断 `code` 是否为 `0`.

**成功 (非分页)**
```json
{
    "code": 0,
    "message": "ok",
    "data": { ... }
}
```

**成功 (分页列表)**
```json
{
    "code": 0,
    "message": "ok",
    "data": {
        "list": [ ... ],
        "total": 150,
        "page": 1,
        "page_size": 20
    }
}
```

**失败**
```json
{
    "code": 40001,
    "message": "具体的错误描述",
    "data": null
}
```

### 错误码表

| code | HTTP 状态码 | 含义 | 典型场景 |
|------|------------|------|---------|
| 0 | 200 | 成功 | 所有正常响应 |
| 40001 | 400 | 参数校验失败 | 金额为负数、邮箱格式错误、必填字段缺失 |
| 40101 | 401 | 未登录或 Token 无效 | 请求头没有 Token、Token 签名被篡改 |
| 40102 | 401 | Token 已过期 | 7 天有效期已到 |
| 40301 | 403 | 无权限 | 尝试访问别人的数据 |
| 40401 | 404 | 资源不存在 | ID 不存在或不属于当前用户 |
| 40901 | 409 | 版本冲突 | 乐观锁冲突, 两个请求同时修改同一条数据 |
| 42201 | 422 | 业务规则不满足 | 邮箱已注册、账户数达上限、分类名重复、账户已停用 |
| 50001 | 500 | 服务器内部错误 | 数据库异常等不可预见错误 |

### 分页参数

适用于所有返回列表的接口:

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| page | int | 否 | 1 | 页码, 从 1 开始 |
| page_size | int | 否 | 20 | 每页条数, 最大 50, 超过 50 自动重置为 20 |

### 鉴权方式

除注册和登录外的所有接口, 请求头必须携带:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Token 有效期 7 天. 过期后需要重新登录获取.

---

## 一、鉴权接口 (公开, 无需 Token)

### 1. 注册

创建新用户账号. 注册成功后自动创建 14 个默认分类 (9 个支出 + 5 个收入).

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `POST /api/auth/register` |
| 鉴权 | 不需要 |
| Content-Type | application/json |

**请求参数 (Body)**

| 字段 | 类型 | 必填 | 约束 | 说明 |
|------|------|------|------|------|
| email | string | 是 | 合法邮箱格式 | 登录邮箱, 全局唯一 |
| password | string | 是 | 最少 8 个字符 | 登录密码, 服务端 bcrypt 哈希存储 |
| nickname | string | 否 | 最多 50 个字符 | 用户昵称, 不传则为空字符串 |

**请求示例**

```http
POST /api/auth/register HTTP/1.1
Host: 115.190.125.177:8080
Content-Type: application/json

{
    "email": "test@example.com",
    "password": "12345678",
    "nickname": "小明"
}
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": {
        "id": 1,
        "email": "test@example.com",
        "nickname": "小明"
    }
}
```

**响应字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| data.id | uint64 | 新用户的 ID |
| data.email | string | 注册邮箱 |

### 2. 登录

使用邮箱和密码登录, 返回 JWT Token.

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `POST /api/auth/login` |
| 鉴权 | 不需要 |
| Content-Type | application/json |

**请求参数 (Body)**

| 字段 | 类型 | 必填 | 约束 | 说明 |
|------|------|------|------|------|
| email | string | 是 | 合法邮箱格式 | 注册时使用的邮箱 |
| password | string | 是 | - | 登录密码 |

**请求示例**

```http
POST /api/auth/login HTTP/1.1
Host: 115.190.125.177:8080
Content-Type: application/json

{
    "email": "test@example.com",
    "password": "12345678"
}
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": {
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE3MDcyNjQwMDB9.xxxxx",
        "expires_at": "2024-02-07T12:00:00Z"
    }
}
```

**响应字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| data.token | string | JWT Token, 后续所有请求放在 Authorization Header 中 |
| data.expires_at | string | Token 过期时间, ISO 8601 格式 |

**错误响应示例**

邮箱或密码错误:
```json
{
    "code": 40101,
    "message": "未登录或 Token 无效",
    "data": null
}
```

---

## 二、账户接口 (需要 Token)

### 3. 创建账户

为当前用户创建一个新的资金账户. 每个用户最多 20 个账户.

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `POST /api/accounts` |
| 鉴权 | 需要 Bearer Token |
| Content-Type | application/json |

**请求参数 (Body)**

| 字段 | 类型 | 必填 | 约束 | 说明 |
|------|------|------|------|------|
| name | string | 是 | 最多 50 个字符 | 账户名称, 如"招商银行储蓄卡" |
| type | string | 是 | 枚举: `cash` / `bank_card` / `e_wallet` / `other` | 账户类型 |
| initial_balance | int64 | 否 | 默认 0 | 初始余额, 单位: 分. 如 10000 表示 100.00 元 |

**请求示例**

```http
POST /api/accounts HTTP/1.1
Host: 115.190.125.177:8080
Content-Type: application/json
Authorization: Bearer eyJhbGci...

{
    "name": "招商银行储蓄卡",
    "type": "bank_card",
    "initial_balance": 10000000
}
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": {
        "id": 1,
        "user_id": 1,
        "name": "招商银行储蓄卡",
        "type": "bank_card",
        "balance": 10000000,
        "initial_balance": 10000000,
        "is_active": 1,
        "version": 1,
        "created_at": "2024-01-31T10:00:00Z",
        "updated_at": "2024-01-31T10:00:00Z"
    }
}
```

**响应字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| data.id | uint64 | 账户 ID |
| data.user_id | uint64 | 所属用户 ID |
| data.name | string | 账户名称 |
| data.type | string | 账户类型 |
| data.balance | int64 | 当前余额 (分). 创建时等于 initial_balance |
| data.initial_balance | int64 | 初始余额 (分) |
| data.is_active | int8 | 是否启用: 1=启用, 0=停用 |
| data.version | uint32 | 乐观锁版本号, 创建时为 1 |
| data.created_at | string | 创建时间 |
| data.updated_at | string | 最后更新时间 |

**错误响应示例**

账户数量已达上限:
```json
{
    "code": 42201,
    "message": "账户数量已达上限(20)",
    "data": null
}
```

无效的账户类型:
```json
{
    "code": 40001,
    "message": "无效的账户类型",
    "data": null
}
```

---


### 4. 账户列表

查询当前用户的所有账户 (含启用和停用). 单用户最多 20 个, 无需分页.

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `GET /api/accounts` |
| 鉴权 | 需要 Bearer Token |

**请求参数**: 无

**请求示例**

```http
GET /api/accounts HTTP/1.1
Host: 115.190.125.177:8080
Authorization: Bearer eyJhbGci...
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": [
        {
            "id": 1,
            "user_id": 1,
            "name": "招商银行储蓄卡",
            "type": "bank_card",
            "balance": 9650000,
            "initial_balance": 10000000,
            "is_active": 1,
            "version": 4,
            "created_at": "2024-01-31T10:00:00Z",
            "updated_at": "2024-01-31T15:30:00Z"
        },
        {
            "id": 2,
            "user_id": 1,
            "name": "现金",
            "type": "cash",
            "balance": 50000,
            "initial_balance": 100000,
            "is_active": 1,
            "version": 2,
            "created_at": "2024-01-31T10:05:00Z",
            "updated_at": "2024-01-31T14:00:00Z"
        }
    ]
}
```

> 返回的是数组, 不是分页结构. `data` 直接就是账户列表.

---

### 5. 编辑账户

修改账户的名称、类型或启用状态. **不能直接修改余额** (余额只能通过新增/编辑/删除流水来联动变化).

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `PUT /api/accounts/:id` |
| 鉴权 | 需要 Bearer Token |
| Content-Type | application/json |

**路径参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | uint64 | 账户 ID |

**请求参数 (Body)**

所有字段均为可选, 只传需要修改的字段:

| 字段 | 类型 | 必填 | 约束 | 说明 |
|------|------|------|------|------|
| name | string | 否 | 最多 50 个字符 | 新的账户名称 |
| type | string | 否 | 枚举: `cash` / `bank_card` / `e_wallet` / `other` | 新的账户类型 |
| is_active | int8 | 否 | 0 或 1 | 0=停用, 1=启用 |

**请求示例 — 修改名称**

```http
PUT /api/accounts/1 HTTP/1.1
Host: 115.190.125.177:8080
Content-Type: application/json
Authorization: Bearer eyJhbGci...

{
    "name": "招行工资卡"
}
```

**请求示例 — 停用账户**

```http
PUT /api/accounts/2 HTTP/1.1
Host: 115.190.125.177:8080
Content-Type: application/json
Authorization: Bearer eyJhbGci...

{
    "is_active": 0
}
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": {
        "id": 1,
        "user_id": 1,
        "name": "招行工资卡",
        "type": "bank_card",
        "balance": 9650000,
        "initial_balance": 10000000,
        "is_active": 1,
        "version": 4,
        "created_at": "2024-01-31T10:00:00Z",
        "updated_at": "2024-01-31T16:00:00Z"
    }
}
```

**错误响应示例**

账户不存在或不属于当前用户:
```json
{
    "code": 40401,
    "message": "资源不存在",
    "data": null
}
```

---

## 三、分类接口 (需要 Token)

### 6. 创建分类

为当前用户创建自定义分类. 同一用户 + 同一类型 (income/expense) 下名称不能重复.

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `POST /api/categories` |
| 鉴权 | 需要 Bearer Token |
| Content-Type | application/json |

**请求参数 (Body)**

| 字段 | 类型 | 必填 | 约束 | 说明 |
|------|------|------|------|------|
| name | string | 是 | 最多 50 个字符 | 分类名称 |
| type | string | 是 | 枚举: `income` / `expense` | 分类方向 |

**请求示例**

```http
POST /api/categories HTTP/1.1
Host: 115.190.125.177:8080
Content-Type: application/json
Authorization: Bearer eyJhbGci...

{
    "name": "宠物",
    "type": "expense"
}
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": {
        "id": 15,
        "user_id": 1,
        "name": "宠物",
        "type": "expense",
        "is_system": 0,
        "is_active": 1,
        "created_at": "2024-01-31T16:00:00Z",
        "updated_at": "2024-01-31T16:00:00Z"
    }
}
```

**响应字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| data.id | uint64 | 分类 ID |
| data.user_id | uint64 | 所属用户 ID |
| data.name | string | 分类名称 |
| data.type | string | `income` 或 `expense` |
| data.is_system | int8 | 是否系统预置: 1=系统预置 (不可删改名), 0=用户自建 |
| data.is_active | int8 | 是否启用: 1=启用, 0=停用 |
| data.created_at | string | 创建时间 |
| data.updated_at | string | 最后更新时间 |

**错误响应示例**

分类名重复:
```json
{
    "code": 42201,
    "message": "该分类名已存在",
    "data": null
}
```

---

### 7. 分类列表

查询当前用户的所有分类, 可通过 `type` 参数筛选.

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `GET /api/categories` |
| 鉴权 | 需要 Bearer Token |

**查询参数 (Query)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| type | string | 否 | 筛选分类方向: `income` 或 `expense`. 不传则返回全部 |

**请求示例 — 查全部**

```http
GET /api/categories HTTP/1.1
Host: 115.190.125.177:8080
Authorization: Bearer eyJhbGci...
```

**请求示例 — 只查支出分类**

```http
GET /api/categories?type=expense HTTP/1.1
Host: 115.190.125.177:8080
Authorization: Bearer eyJhbGci...
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": [
        {
            "id": 1,
            "user_id": 1,
            "name": "餐饮",
            "type": "expense",
            "is_system": 1,
            "is_active": 1,
            "created_at": "2024-01-31T10:00:00Z",
            "updated_at": "2024-01-31T10:00:00Z"
        },
        {
            "id": 10,
            "user_id": 1,
            "name": "工资",
            "type": "income",
            "is_system": 1,
            "is_active": 1,
            "created_at": "2024-01-31T10:00:00Z",
            "updated_at": "2024-01-31T10:00:00Z"
        },
        {
            "id": 15,
            "user_id": 1,
            "name": "宠物",
            "type": "expense",
            "is_system": 0,
            "is_active": 1,
            "created_at": "2024-01-31T16:00:00Z",
            "updated_at": "2024-01-31T16:00:00Z"
        }
    ]
}
```

> 返回数组, 不分页. 新注册用户默认有 14 个系统预置分类 (9 支出 + 5 收入).
>
> 系统预置分类 — 支出: 餐饮 / 交通 / 购物 / 住房 / 娱乐 / 医疗 / 教育 / 通讯 / 其他支出; 收入: 工资 / 奖金 / 投资收益 / 兼职 / 其他收入.

---

### 8. 编辑分类

修改分类名称或启用状态. 只传需要修改的字段.

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `PUT /api/categories/:id` |
| 鉴权 | 需要 Bearer Token |
| Content-Type | application/json |

**路径参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | uint64 | 分类 ID |

**请求参数 (Body)**

| 字段 | 类型 | 必填 | 约束 | 说明 |
|------|------|------|------|------|
| name | string | 否 | 最多 50 个字符 | 新的分类名称 |
| is_active | int8 | 否 | 0 或 1 | 0=停用, 1=启用 |

**请求示例**

```http
PUT /api/categories/15 HTTP/1.1
Host: 115.190.125.177:8080
Content-Type: application/json
Authorization: Bearer eyJhbGci...

{
    "name": "宠物用品"
}
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": {
        "id": 15,
        "user_id": 1,
        "name": "宠物用品",
        "type": "expense",
        "is_system": 0,
        "is_active": 1,
        "created_at": "2024-01-31T16:00:00Z",
        "updated_at": "2024-01-31T17:00:00Z"
    }
}
```

**错误响应示例**

修改后名称与同类型下已有分类重名:
```json
{
    "code": 42201,
    "message": "该分类名已存在",
    "data": null
}
```

---

## 四、流水接口 (需要 Token, 核心接口)

### 9. 新增流水

记录一笔收入或支出. 在同一个数据库事务内完成: 插入流水记录 + 乐观锁更新账户余额.

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `POST /api/transactions` |
| 鉴权 | 需要 Bearer Token |
| Content-Type | application/json |

**请求参数 (Body)**

| 字段 | 类型 | 必填 | 约束 | 说明 |
|------|------|------|------|------|
| account_id | uint64 | 是 | - | 关联的账户 ID, 必须属于当前用户且为启用状态 |
| category_id | uint64 | 是 | - | 关联的分类 ID, 必须属于当前用户 |
| type | string | 是 | 枚举: `income` / `expense` | 流水方向 |
| amount | int64 | 是 | > 0, 最大 9999999999 | 金额, 单位: 分. 始终为正数, 由 type 决定加减 |
| note | string | 否 | 最多 200 个字符 | 备注信息 |
| transaction_at | string | 是 | ISO 8601 格式 | 记账时间, 用户选择的时间而非系统时间 |

**请求示例**

```http
POST /api/transactions HTTP/1.1
Host: 115.190.125.177:8080
Content-Type: application/json
Authorization: Bearer eyJhbGci...

{
    "account_id": 1,
    "category_id": 1,
    "type": "expense",
    "amount": 3550,
    "note": "午餐 — 沙县小吃",
    "transaction_at": "2024-01-31T12:30:00Z"
}
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": {
        "id": 101,
        "account_id": 1,
        "new_balance": 9996450,
        "new_version": 5
    }
}
```

**响应字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| data.id | uint64 | 新创建的流水 ID |
| data.account_id | uint64 | 关联的账户 ID |
| data.new_balance | int64 | 操作后的账户余额 (分) |
| data.new_version | uint32 | 操作后的账户版本号 |

**错误响应示例**

账户已停用:
```json
{
    "code": 42201,
    "message": "该账户已停用, 无法记账",
    "data": null
}
```

余额版本冲突 (并发操作):
```json
{
    "code": 40901,
    "message": "账户余额版本冲突, 请重试",
    "data": null
}
```

---

### 10. 流水列表 (分页 + 筛选)

分页查询当前用户的流水记录, 支持按账户、分类、类型、时间范围筛选. 返回结果包含关联的分类名和账户名.

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `GET /api/transactions` |
| 鉴权 | 需要 Bearer Token |

**查询参数 (Query)**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| page | int | 否 | 1 | 页码, 从 1 开始 |
| page_size | int | 否 | 20 | 每页条数, 最大 50 |
| account_id | uint64 | 否 | - | 按账户 ID 筛选 |
| category_id | uint64 | 否 | - | 按分类 ID 筛选 |
| type | string | 否 | - | 按方向筛选: `income` 或 `expense` |
| start_date | string | 否 | - | 开始日期, 格式 `2024-01-01` |
| end_date | string | 否 | - | 结束日期, 格式 `2024-01-31` (包含当天) |

**请求示例 — 查 1 月份所有支出**

```http
GET /api/transactions?page=1&page_size=20&type=expense&start_date=2024-01-01&end_date=2024-01-31 HTTP/1.1
Host: 115.190.125.177:8080
Authorization: Bearer eyJhbGci...
```

**请求示例 — 查某个账户的流水**

```http
GET /api/transactions?account_id=1&page=1&page_size=10 HTTP/1.1
Host: 115.190.125.177:8080
Authorization: Bearer eyJhbGci...
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": {
        "list": [
            {
                "id": 101,
                "user_id": 1,
                "account_id": 1,
                "category_id": 1,
                "type": "expense",
                "amount": 3550,
                "note": "午餐 — 沙县小吃",
                "transaction_at": "2024-01-31T12:30:00Z",
                "source_type": "manual",
                "version": 1,
                "created_at": "2024-01-31T12:35:00Z",
                "updated_at": "2024-01-31T12:35:00Z",
                "category_name": "餐饮",
                "account_name": "招商银行储蓄卡"
            },
            {
                "id": 100,
                "user_id": 1,
                "account_id": 1,
                "category_id": 10,
                "type": "income",
                "amount": 800000,
                "note": "1月工资",
                "transaction_at": "2024-01-15T09:00:00Z",
                "source_type": "manual",
                "version": 1,
                "created_at": "2024-01-15T09:05:00Z",
                "updated_at": "2024-01-15T09:05:00Z",
                "category_name": "工资",
                "account_name": "招商银行储蓄卡"
            }
        ],
        "total": 2,
        "page": 1,
        "page_size": 20
    }
}
```

**响应字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| data.list | array | 流水记录数组, 按 transaction_at 倒序排列 |
| data.list[].category_name | string | 关联分类的名称 (JOIN 查询) |
| data.list[].account_name | string | 关联账户的名称 (JOIN 查询) |
| data.total | int64 | 符合筛选条件的总记录数 |
| data.page | int | 当前页码 |
| data.page_size | int | 每页条数 |

> 列表中不包含已软删除 (deleted_at 不为 NULL) 的流水.

---

### 11. 流水详情

查询单条流水记录的完整信息.

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `GET /api/transactions/:id` |
| 鉴权 | 需要 Bearer Token |

**路径参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | uint64 | 流水 ID |

**请求示例**

```http
GET /api/transactions/101 HTTP/1.1
Host: 115.190.125.177:8080
Authorization: Bearer eyJhbGci...
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": {
        "id": 101,
        "user_id": 1,
        "account_id": 1,
        "category_id": 1,
        "type": "expense",
        "amount": 3550,
        "note": "午餐 — 沙县小吃",
        "transaction_at": "2024-01-31T12:30:00Z",
        "source_type": "manual",
        "version": 1,
        "created_at": "2024-01-31T12:35:00Z",
        "updated_at": "2024-01-31T12:35:00Z"
    }
}
```

**错误响应示例**

流水不存在或不属于当前用户:
```json
{
    "code": 40401,
    "message": "资源不存在",
    "data": null
}
```

---

### 12. 编辑流水

修改一条已有的流水记录. 在同一个数据库事务内完成: 回滚旧余额影响 + 应用新余额影响 + 乐观锁校验.

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `PUT /api/transactions/:id` |
| 鉴权 | 需要 Bearer Token |
| Content-Type | application/json |

**路径参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | uint64 | 流水 ID |

**请求参数 (Body)**

所有字段均为可选 (除 `version` 外), 只传需要修改的字段:

| 字段 | 类型 | 必填 | 约束 | 说明 |
|------|------|------|------|------|
| account_id | uint64 | 否 | - | 修改关联账户 (换到另一个账户) |
| category_id | uint64 | 否 | - | 修改关联分类 |
| type | string | 否 | 枚举: `income` / `expense` | 修改方向 |
| amount | int64 | 否 | > 0 | 修改金额, 单位: 分 |
| note | string | 否 | 最多 200 个字符 | 修改备注 |
| transaction_at | string | 否 | ISO 8601 格式 | 修改记账时间 |
| version | uint32 | **是** | - | 当前版本号, 用于乐观锁校验. 从详情/列表接口获取 |

> `version` 是必填的. 编辑前先查详情拿到当前 version, 提交时带上. 如果提交时 version 和数据库中的不一致, 说明被别的请求改过了, 返回 409.

**请求示例 — 修改金额和备注**

```http
PUT /api/transactions/101 HTTP/1.1
Host: 115.190.125.177:8080
Content-Type: application/json
Authorization: Bearer eyJhbGci...

{
    "amount": 4200,
    "note": "午餐 — 沙县小吃 + 奶茶",
    "version": 1
}
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": null
}
```

**错误响应示例**

版本冲突 (有人先你一步修改了这条流水):
```json
{
    "code": 40901,
    "message": "流水版本冲突, 请重试",
    "data": null
}
```

---

### 13. 删除流水 (软删除)

软删除一条流水记录 (设置 deleted_at, 不物理删除). 同时在事务内回滚该流水对账户余额的影响.

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `DELETE /api/transactions/:id` |
| 鉴权 | 需要 Bearer Token |

**路径参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| id | uint64 | 流水 ID |

**查询参数 (Query)**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| version | uint32 | 是 | 当前版本号, 用于乐观锁校验 |

> 注意: 删除接口没有 Body, version 通过 Query 参数传递.

**请求示例**

```http
DELETE /api/transactions/101?version=1 HTTP/1.1
Host: 115.190.125.177:8080
Authorization: Bearer eyJhbGci...
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": null
}
```

**错误响应示例**

版本冲突:
```json
{
    "code": 40901,
    "message": "流水版本冲突, 请重试",
    "data": null
}
```

流水不存在:
```json
{
    "code": 40401,
    "message": "资源不存在",
    "data": null
}
```

---

## 五、统计接口 (需要 Token)

### 14. 月度统计

查询某个月的总收入、总支出和结余 (收入 - 支出). 不传 year/month 时默认查当前月.

**基本信息**

| 项目 | 值 |
|------|-----|
| URL | `GET /api/stats/monthly` |
| 鉴权 | 需要 Bearer Token |

**查询参数 (Query)**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| year | int | 否 | 当前年 | 年份, 如 2024 |
| month | int | 否 | 当前月 | 月份, 1~12 |

**请求示例 — 查 2024 年 1 月**

```http
GET /api/stats/monthly?year=2024&month=1 HTTP/1.1
Host: 115.190.125.177:8080
Authorization: Bearer eyJhbGci...
```

**请求示例 — 查当前月 (不传参)**

```http
GET /api/stats/monthly HTTP/1.1
Host: 115.190.125.177:8080
Authorization: Bearer eyJhbGci...
```

**成功响应** `200 OK`

```json
{
    "code": 0,
    "message": "ok",
    "data": {
        "year": 2024,
        "month": 1,
        "total_income": 800000,
        "total_expense": 350000,
        "balance": 450000
    }
}
```

**响应字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| data.year | int | 查询的年份 |
| data.month | int | 查询的月份 |
| data.total_income | int64 | 该月总收入 (分). 如 800000 = 8000.00 元 |
| data.total_expense | int64 | 该月总支出 (分). 如 350000 = 3500.00 元 |
| data.balance | int64 | 结余 = total_income - total_expense (分) |

> 金额均为整数, 单位: 分. 前端展示时除以 100 即可.
>
> 当该月没有任何流水时, total_income、total_expense、balance 全部为 0.

---

## 附录: 完整接口速查表

| 序号 | 方法 | URL | 鉴权 | 说明 |
|------|------|-----|------|------|
| 1 | POST | /api/auth/register | 否 | 注册 |
| 2 | POST | /api/auth/login | 否 | 登录 |
| 3 | POST | /api/accounts | 是 | 创建账户 |
| 4 | GET | /api/accounts | 是 | 账户列表 |
| 5 | PUT | /api/accounts/:id | 是 | 编辑账户 |
| 6 | POST | /api/categories | 是 | 创建分类 |
| 7 | GET | /api/categories | 是 | 分类列表 |
| 8 | PUT | /api/categories/:id | 是 | 编辑分类 |
| 9 | POST | /api/transactions | 是 | 新增流水 |
| 10 | GET | /api/transactions | 是 | 流水列表 (分页+筛选) |
| 11 | GET | /api/transactions/:id | 是 | 流水详情 |
| 12 | PUT | /api/transactions/:id | 是 | 编辑流水 |
| 13 | DELETE | /api/transactions/:id | 是 | 删除流水 (软删除) |
| 14 | GET | /api/stats/monthly | 是 | 月度统计 |