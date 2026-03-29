package handler

import (
	"strconv"

	"github.com/GoLedger/backend/internal/middleware"
	"github.com/GoLedger/backend/internal/pkg/errs"
	"github.com/GoLedger/backend/internal/pkg/response"
	"github.com/GoLedger/backend/internal/service"
	"github.com/gin-gonic/gin"
)

type AccountHandler struct {
	accountService *service.AccountService
}

func NewAccountHandler(accountService *service.AccountService) *AccountHandler {
	return &AccountHandler{accountService: accountService}
}

// Create handles POST /api/accounts
func (h *AccountHandler) Create(c *gin.Context) {
	userID := middleware.GetUserID(c)

	var req service.CreateAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, err.Error()))
		return
	}

	account, err := h.accountService.Create(userID, &req)
	if err != nil {
		handleError(c, err)
		return
	}

	response.OK(c, account)
}

// List handles GET /api/accounts
func (h *AccountHandler) List(c *gin.Context) {
	userID := middleware.GetUserID(c)

	accounts, err := h.accountService.List(userID)
	if err != nil {
		handleError(c, err)
		return
	}

	response.OK(c, accounts)
}

// Update handles PUT /api/accounts/:id
func (h *AccountHandler) Update(c *gin.Context) {
	userID := middleware.GetUserID(c)
	accountID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, "无效的账户ID"))
		return
	}

	var req service.UpdateAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, err.Error()))
		return
	}

	account, err := h.accountService.Update(userID, accountID, &req)
	if err != nil {
		handleError(c, err)
		return
	}

	response.OK(c, account)
}

