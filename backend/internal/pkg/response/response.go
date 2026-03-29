package response

import (
	"net/http"

	"github.com/GoLedger/backend/internal/pkg/errs"
	"github.com/gin-gonic/gin"
)

// R is the unified JSON response structure.
type R struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

// PageData wraps paginated results.
type PageData struct {
	List     interface{} `json:"list"`
	Total    int64       `json:"total"`
	Page     int         `json:"page"`
	PageSize int         `json:"page_size"`
}

// OK sends a successful response.
func OK(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, R{
		Code:    0,
		Message: "ok",
		Data:    data,
	})
}

// OKPage sends a paginated successful response.
func OKPage(c *gin.Context, list interface{}, total int64, page, pageSize int) {
	c.JSON(http.StatusOK, R{
		Code:    0,
		Message: "ok",
		Data: PageData{
			List:     list,
			Total:    total,
			Page:     page,
			PageSize: pageSize,
		},
	})
}

// Fail sends an error response based on AppError.
func Fail(c *gin.Context, err *errs.AppError) {
	c.JSON(err.HTTPStatus, R{
		Code:    err.Code,
		Message: err.Message,
		Data:    nil,
	})
}

// FailWithData sends an error response with additional data (e.g., version conflict).
func FailWithData(c *gin.Context, err *errs.AppError, data interface{}) {
	c.JSON(err.HTTPStatus, R{
		Code:    err.Code,
		Message: err.Message,
		Data:    data,
	})
}

