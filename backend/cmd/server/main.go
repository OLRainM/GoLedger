package main

import (
	"fmt"
	"log"
	"time"

	"github.com/GoLedger/backend/internal/config"
	"github.com/GoLedger/backend/internal/handler"
	"github.com/GoLedger/backend/internal/middleware"
	jwtPkg "github.com/GoLedger/backend/internal/pkg/jwt"
	"github.com/GoLedger/backend/internal/pkg/response"
	"github.com/GoLedger/backend/internal/repository"
	"github.com/GoLedger/backend/internal/service"
	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
	"github.com/gocraft/dbr/v2"
	"go.uber.org/zap"
)

func main() {
	// 1. Load config
	cfg, err := config.Load("config.yaml")
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}

	// 2. Init logger
	var logger *zap.Logger
	if cfg.Server.Mode == "release" {
		logger, _ = zap.NewProduction()
	} else {
		logger, _ = zap.NewDevelopment()
	}
	defer logger.Sync()

	// 3. Init JWT
	jwtPkg.Init(cfg.JWT.Secret, cfg.JWT.ExpireDuration())

	// 4. Connect database via dbr
	dsn := cfg.Database.DSN()
	conn, err := dbr.Open("mysql", dsn, nil)
	if err != nil {
		logger.Fatal("failed to open database", zap.Error(err))
	}
	conn.SetMaxOpenConns(cfg.Database.MaxOpenConns)
	conn.SetMaxIdleConns(cfg.Database.MaxIdleConns)
	conn.SetConnMaxLifetime(time.Duration(cfg.Database.ConnMaxLifetime) * time.Second)

	// Ping to verify connection
	if err := conn.Ping(); err != nil {
		logger.Fatal("failed to ping database", zap.Error(err))
	}
	logger.Info("database connected", zap.String("host", cfg.Database.Host))

	sess := conn.NewSession(nil)

	// 5. Init repositories
	userRepo := repository.NewUserRepo(sess)
	accountRepo := repository.NewAccountRepo(sess)
	categoryRepo := repository.NewCategoryRepo(sess)
	txnRepo := repository.NewTransactionRepo(sess)

	// 6. Init services
	authService := service.NewAuthService(userRepo, categoryRepo, sess)
	accountService := service.NewAccountService(accountRepo)
	categoryService := service.NewCategoryService(categoryRepo)
	txnService := service.NewTransactionService(txnRepo, accountRepo, categoryRepo, sess)
	statsService := service.NewStatsService(txnRepo)

	// 7. Init handlers
	authHandler := handler.NewAuthHandler(authService)
	accountHandler := handler.NewAccountHandler(accountService)
	categoryHandler := handler.NewCategoryHandler(categoryService)
	txnHandler := handler.NewTransactionHandler(txnService)
	statsHandler := handler.NewStatsHandler(statsService)

	// 8. Setup Gin
	gin.SetMode(cfg.Server.Mode)
	r := gin.New()
	r.Use(middleware.CORS())
	r.Use(middleware.Logger(logger))
	r.Use(gin.Recovery())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		response.OK(c, gin.H{"status": "ok"})
	})

	// Public routes
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
	}

	// Protected routes
	api := r.Group("/api", middleware.Auth())
	{
		accounts := api.Group("/accounts")
		{
			accounts.POST("", accountHandler.Create)
			accounts.GET("", accountHandler.List)
			accounts.PUT("/:id", accountHandler.Update)
		}

		categories := api.Group("/categories")
		{
			categories.POST("", categoryHandler.Create)
			categories.GET("", categoryHandler.List)
			categories.PUT("/:id", categoryHandler.Update)
		}

		transactions := api.Group("/transactions")
		{
			transactions.POST("", txnHandler.Create)
			transactions.GET("", txnHandler.List)
			transactions.GET("/:id", txnHandler.GetByID)
			transactions.PUT("/:id", txnHandler.Update)
			transactions.DELETE("/:id", txnHandler.Delete)
		}

		stats := api.Group("/stats")
		{
			stats.GET("/monthly", statsHandler.MonthlySummary)
		}
	}

	// 9. Start server
	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	logger.Info("server starting", zap.String("addr", addr))
	if err := r.Run(addr); err != nil {
		logger.Fatal("failed to start server", zap.Error(err))
	}
}
