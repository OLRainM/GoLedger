package handler

import (
	"strconv"
	"time"

	"github.com/GoLedger/backend/internal/middleware"
	"github.com/GoLedger/backend/internal/pkg/errs"
	"github.com/GoLedger/backend/internal/pkg/response"
	"github.com/GoLedger/backend/internal/repository"
	"github.com/GoLedger/backend/internal/service"
	"github.com/gin-gonic/gin"
)

type TransactionHandler struct {
	txnService *service.TransactionService
}

func NewTransactionHandler(txnService *service.TransactionService) *TransactionHandler {
	return &TransactionHandler{txnService: txnService}
}

// Create handles POST /api/transactions
func (h *TransactionHandler) Create(c *gin.Context) {
	userID := middleware.GetUserID(c)

	var req service.CreateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, err.Error()))
		return
	}

	resp, err := h.txnService.Create(userID, &req)
	if err != nil {
		handleError(c, err)
		return
	}

	response.OK(c, resp)
}

// List handles GET /api/transactions
func (h *TransactionHandler) List(c *gin.Context) {
	userID := middleware.GetUserID(c)

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 20
	}

	filter := repository.ListFilter{
		UserID:   userID,
		Page:     page,
		PageSize: pageSize,
	}

	if v := c.Query("account_id"); v != "" {
		id, _ := strconv.ParseUint(v, 10, 64)
		filter.AccountID = &id
	}
	if v := c.Query("category_id"); v != "" {
		id, _ := strconv.ParseUint(v, 10, 64)
		filter.CategoryID = &id
	}
	if v := c.Query("type"); v != "" {
		filter.Type = v
	}
	if v := c.Query("start_date"); v != "" {
		if t, err := time.Parse("2006-01-02", v); err == nil {
			filter.StartDate = &t
		}
	}
	if v := c.Query("end_date"); v != "" {
		if t, err := time.Parse("2006-01-02", v); err == nil {
			end := t.Add(24*time.Hour - time.Nanosecond) // end of day
			filter.EndDate = &end
		}
	}

	list, total, err := h.txnService.List(filter)
	if err != nil {
		handleError(c, err)
		return
	}

	response.OKPage(c, list, total, page, pageSize)
}

// GetByID handles GET /api/transactions/:id
func (h *TransactionHandler) GetByID(c *gin.Context) {
	userID := middleware.GetUserID(c)
	txnID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, "无效的流水ID"))
		return
	}

	txn, err := h.txnService.GetByID(userID, txnID)
	if err != nil {
		handleError(c, err)
		return
	}

	response.OK(c, txn)
}

// Update handles PUT /api/transactions/:id
func (h *TransactionHandler) Update(c *gin.Context) {
	userID := middleware.GetUserID(c)
	txnID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, "无效的流水ID"))
		return
	}

	var req service.UpdateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, err.Error()))
		return
	}

	if err := h.txnService.Update(userID, txnID, &req); err != nil {
		handleError(c, err)
		return
	}

	response.OK(c, nil)
}

// Delete handles DELETE /api/transactions/:id
func (h *TransactionHandler) Delete(c *gin.Context) {
	userID := middleware.GetUserID(c)
	txnID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, "无效的流水ID"))
		return
	}

	// Version is passed as query param for DELETE
	version, err := strconv.ParseUint(c.Query("version"), 10, 32)
	if err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, "缺少 version 参数"))
		return
	}

	if err := h.txnService.Delete(userID, txnID, uint32(version)); err != nil {
		handleError(c, err)
		return
	}

	response.OK(c, nil)
}
