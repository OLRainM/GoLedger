package main

import (
	"github.com/GoLedger/backend/internal/handler"
	"github.com/GoLedger/backend/internal/middleware"
	"github.com/GoLedger/backend/internal/pkg/response"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// setupRouter 创建并配置 Gin 引擎，注册全部路由。
func setupRouter(
	mode string,
	logger *zap.Logger,
	authHandler *handler.AuthHandler,
	accountHandler *handler.AccountHandler,
	categoryHandler *handler.CategoryHandler,
	txnHandler *handler.TransactionHandler,
	statsHandler *handler.StatsHandler,
) *gin.Engine {
	gin.SetMode(mode)
	r := gin.New()
	r.Use(middleware.CORS())
	r.Use(middleware.Logger(logger))
	r.Use(gin.Recovery())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		response.OK(c, gin.H{"status": "ok"})
	})

	// ──────────────────────────────────────
	// 公开接口 (无需 Token)
	// ──────────────────────────────────────
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", authHandler.Register) // 注册
		auth.POST("/login", authHandler.Login)        // 登录
	}

	// ──────────────────────────────────────
	// 需鉴权接口 (JWT)
	// ──────────────────────────────────────
	api := r.Group("/api", middleware.Auth())
	{
		// 账户
		accounts := api.Group("/accounts")
		{
			accounts.POST("", accountHandler.Create)    // 创建账户
			accounts.GET("", accountHandler.List)        // 账户列表
			accounts.PUT("/:id", accountHandler.Update)  // 编辑账户
		}

		// 分类
		categories := api.Group("/categories")
		{
			categories.POST("", categoryHandler.Create)    // 创建分类
			categories.GET("", categoryHandler.List)        // 分类列表
			categories.PUT("/:id", categoryHandler.Update)  // 编辑分类
		}

		// 流水
		transactions := api.Group("/transactions")
		{
			transactions.POST("", txnHandler.Create)          // 新增流水
			transactions.GET("", txnHandler.List)              // 流水列表 (分页+筛选)
			transactions.GET("/:id", txnHandler.GetByID)       // 流水详情
			transactions.PUT("/:id", txnHandler.Update)        // 编辑流水
			transactions.DELETE("/:id", txnHandler.Delete)     // 删除流水 (软删除)
		}

		// 统计
		stats := api.Group("/stats")
		{
			stats.GET("/monthly", statsHandler.MonthlySummary) // 月度统计
		}
	}

	return r
}

