package errs

import "net/http"

// AppError represents a structured business error.
type AppError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	HTTPStatus int `json:"-"`
}

func (e *AppError) Error() string {
	return e.Message
}

// Pre-defined error codes matching the require.md spec.
var (
	ErrBadRequest      = &AppError{Code: 40001, Message: "参数校验失败", HTTPStatus: http.StatusBadRequest}
	ErrUnauthorized    = &AppError{Code: 40101, Message: "未登录或 Token 无效", HTTPStatus: http.StatusUnauthorized}
	ErrTokenExpired    = &AppError{Code: 40102, Message: "Token 已过期", HTTPStatus: http.StatusUnauthorized}
	ErrForbidden       = &AppError{Code: 40301, Message: "无权限", HTTPStatus: http.StatusForbidden}
	ErrNotFound        = &AppError{Code: 40401, Message: "资源不存在", HTTPStatus: http.StatusNotFound}
	ErrConflict        = &AppError{Code: 40901, Message: "版本冲突", HTTPStatus: http.StatusConflict}
	ErrUnprocessable   = &AppError{Code: 42201, Message: "业务规则不满足", HTTPStatus: http.StatusUnprocessableEntity}
	ErrInternal        = &AppError{Code: 50001, Message: "服务器内部错误", HTTPStatus: http.StatusInternalServerError}
)

// New creates a new AppError with custom message, based on a template error.
func New(base *AppError, message string) *AppError {
	return &AppError{
		Code:       base.Code,
		Message:    message,
		HTTPStatus: base.HTTPStatus,
	}
}

