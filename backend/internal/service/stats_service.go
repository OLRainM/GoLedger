package service

import (
	"time"

	"github.com/GoLedger/backend/internal/repository"
)

type StatsService struct {
	txnRepo *repository.TransactionRepo
}

func NewStatsService(txnRepo *repository.TransactionRepo) *StatsService {
	return &StatsService{txnRepo: txnRepo}
}

type MonthlySummaryResponse struct {
	Year         int   `json:"year"`
	Month        int   `json:"month"`
	TotalIncome  int64 `json:"total_income"`
	TotalExpense int64 `json:"total_expense"`
	Balance      int64 `json:"balance"` // income - expense
}

// GetMonthlySummary returns income/expense totals for a given month.
// If year/month are 0, defaults to current month.
func (s *StatsService) GetMonthlySummary(userID uint64, year, month int) (*MonthlySummaryResponse, error) {
	if year == 0 || month == 0 {
		now := time.Now()
		year = now.Year()
		month = int(now.Month())
	}

	summary, err := s.txnRepo.GetMonthlySummary(userID, year, month)
	if err != nil {
		return nil, err
	}

	return &MonthlySummaryResponse{
		Year:         year,
		Month:        month,
		TotalIncome:  summary.TotalIncome,
		TotalExpense: summary.TotalExpense,
		Balance:      summary.TotalIncome - summary.TotalExpense,
	}, nil
}

