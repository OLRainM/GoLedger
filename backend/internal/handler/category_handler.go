package handler

import (
	"strconv"

	"github.com/GoLedger/backend/internal/middleware"
	"github.com/GoLedger/backend/internal/pkg/errs"
	"github.com/GoLedger/backend/internal/pkg/response"
	"github.com/GoLedger/backend/internal/service"
	"github.com/gin-gonic/gin"
)

type CategoryHandler struct {
	categoryService *service.CategoryService
}

func NewCategoryHandler(categoryService *service.CategoryService) *CategoryHandler {
	return &CategoryHandler{categoryService: categoryService}
}

// Create handles POST /api/categories
func (h *CategoryHandler) Create(c *gin.Context) {
	userID := middleware.GetUserID(c)

	var req service.CreateCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, err.Error()))
		return
	}

	cat, err := h.categoryService.Create(userID, &req)
	if err != nil {
		handleError(c, err)
		return
	}

	response.OK(c, cat)
}

// List handles GET /api/categories
func (h *CategoryHandler) List(c *gin.Context) {
	userID := middleware.GetUserID(c)
	catType := c.Query("type") // optional filter: income | expense

	categories, err := h.categoryService.List(userID, catType)
	if err != nil {
		handleError(c, err)
		return
	}

	response.OK(c, categories)
}

// Update handles PUT /api/categories/:id
func (h *CategoryHandler) Update(c *gin.Context) {
	userID := middleware.GetUserID(c)
	categoryID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, "无效的分类ID"))
		return
	}

	var req service.UpdateCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Fail(c, errs.New(errs.ErrBadRequest, err.Error()))
		return
	}

	cat, err := h.categoryService.Update(userID, categoryID, &req)
	if err != nil {
		handleError(c, err)
		return
	}

	response.OK(c, cat)
}

