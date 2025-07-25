@echo off
echo ========================================
echo 🚀 T-one Streaming Voice Setup Script
echo ========================================
echo.

echo 🔧 Running Windows initialization script...
init\windows.bat
if %ERRORLEVEL% neq 0 (
    echo ❌ Initialization failed
    pause
    exit /b 1
)
echo.

echo ========================================
echo ✅ Setup Complete!
echo ========================================
echo.
echo 🚀 To start the server:
echo    make up_dev          (Compact mode - fast)
echo    make up_dev_full     (Full mode with KenLM - accurate)
echo.
echo 📊 To download full models with KenLM (5.6GB):
echo    make download_full_models
echo.
echo 🌐 Server will be available at: http://localhost:8080
echo.
pause
