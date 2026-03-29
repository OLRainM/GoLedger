package handler

import (
	"github.com/GoLedger/backend/internal/pkg/errs"
	"github.com/GoLedger/backend/internal/pkg/response"
	"github.com/GoLedger/backend/internal/service"
	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	authService *service.AuthService
}

func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// Register handles POST /api/auth/register
func (h *AuthHandler) Register(c *gin.Context) {
	var req service.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, err.Error()))
		return
	}

	resp, err := h.authService.Register(&req)
	if err != nil {
		handleError(c, err)
		return
	}

	response.OK(c, resp)
}

// Login handles POST /api/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req service.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, err.Error()))
		return
	}

	resp, err := h.authService.Login(&req)
	if err != nil {
		handleError(c, err)
		return
	}

	response.OK(c, resp)
}

// handleError converts AppError or generic error to the unified response.
func handleError(c *gin.Context, err error) {
	if appErr, ok := err.(*errs.AppError); ok {
		response.Fail(c, appErr)
		return
	}
	response.Fail(c, errs.ErrInternal)
}

