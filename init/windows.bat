@echo off
echo ========================================
echo 🪟 T-one Windows Initialization
echo ========================================
echo.

REM Check if uv is installed
where uv >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ❌ uv not found. Installing uv...
    echo.
    powershell -Command "irm https://astral.sh/uv/install.ps1 | iex"
    if %ERRORLEVEL% neq 0 (
        echo ❌ Failed to install uv
        echo 📝 Please install manually: https://docs.astral.sh/uv/getting-started/installation/
        pause
        exit /b 1
    )
    echo ✅ uv installed successfully
    echo.
    echo 🔄 Please restart your terminal and run the script again
    pause
    exit /b 0
)

echo ✅ uv found
echo.

REM Create virtual environment if it doesn't exist
if not exist ".venv" (
    echo 📦 Creating virtual environment...
    uv venv .venv
    if %ERRORLEVEL% neq 0 (
        echo ❌ Failed to create virtual environment
        pause
        exit /b 1
    )
    echo ✅ Virtual environment created
) else (
    echo ✅ Virtual environment already exists
)
echo.

REM Install dependencies
echo 📥 Installing Python dependencies...
uv sync --extra demo --extra dev
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)
echo ✅ Dependencies installed
echo.

REM Download models
echo 🤖 Downloading AI models...
make download_models
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to download models
    pause
    exit /b 1
)
echo ✅ Models downloaded
echo.

REM Setup GPU
echo 🔧 Setting up GPU acceleration...
make setup_cudnn
if %ERRORLEVEL% neq 0 (
    echo ⚠️  GPU setup failed, but project will work on CPU
)
echo.

echo ========================================
echo ✅ Windows Setup Complete!
echo ========================================
echo.
echo 🚀 To activate virtual environment:
echo    .\.venv\Scripts\Activate.ps1
echo.
echo 🌐 To start the server:
echo    make up_dev          (Compact mode)
echo    make up_dev_full     (Full mode with KenLM)
echo.
echo 📊 Server will be available at: http://localhost:8080
echo.
echo Press any key to continue...
pause >nul
