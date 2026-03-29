package handler

import (
	"strconv"

	"github.com/GoLedger/backend/internal/middleware"
	"github.com/GoLedger/backend/internal/pkg/errs"
	"github.com/GoLedger/backend/internal/pkg/response"
	"github.com/GoLedger/backend/internal/service"
	"github.com/gin-gonic/gin"
)

type StatsHandler struct {
	statsService *service.StatsService
}

func NewStatsHandler(statsService *service.StatsService) *StatsHandler {
	return &StatsHandler{statsService: statsService}
}

// MonthlySummary handles GET /api/stats/monthly
func (h *StatsHandler) MonthlySummary(c *gin.Context) {
	userID := middleware.GetUserID(c)

	year, _ := strconv.Atoi(c.Query("year"))
	month, _ := strconv.Atoi(c.Query("month"))

	resp, err := h.statsService.GetMonthlySummary(userID, year, month)
	if err != nil {
		if appErr, ok := err.(*errs.AppError); ok {
			response.Fail(c, appErr)
		} else {
			response.Fail(c, errs.ErrInternal)
		}
		return
	}

	response.OK(c, resp)
}

