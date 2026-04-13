package main

import (
	"fmt"
	"log"
	"time"

	"github.com/GoLedger/backend/internal/config"
	"github.com/GoLedger/backend/internal/handler"
	jwtPkg "github.com/GoLedger/backend/internal/pkg/jwt"
	"github.com/GoLedger/backend/internal/repository"
	"github.com/GoLedger/backend/internal/service"
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

	// 8. Setup router (路由定义见 router.go)
	r := setupRouter(
		cfg.Server.Mode, logger,
		authHandler, accountHandler, categoryHandler, txnHandler, statsHandler,
	)

	// 9. Start server
	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	logger.Info("server starting", zap.String("addr", addr))
	if err := r.Run(addr); err != nil {
		logger.Fatal("failed to start server", zap.Error(err))
	}
}
