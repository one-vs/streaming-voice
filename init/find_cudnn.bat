@echo off

echo Searching for cuDNN in system...
echo.

set "FOUND=0"
set "CUDNN_PATH="

REM Check common cuDNN paths
if exist "C:\Program Files\NVIDIA\CUDNN\v9.11\bin\12.9\cudnn64_9.dll" (
    echo Found: C:\Program Files\NVIDIA\CUDNN\v9.11\bin\12.9\cudnn64_9.dll
    set "FOUND=1"
    set "CUDNN_PATH=C:\Program Files\NVIDIA\CUDNN\v9.11\bin\12.9\cudnn64_9.dll"
    goto :found
)

if exist "C:\Program Files\NVIDIA\CUDNN\v9.11\bin\cudnn64_9.dll" (
    echo Found: C:\Program Files\NVIDIA\CUDNN\v9.11\bin\cudnn64_9.dll
    set "FOUND=1"
    set "CUDNN_PATH=C:\Program Files\NVIDIA\CUDNN\v9.11\bin\cudnn64_9.dll"
    goto :found
)

if exist "C:\Program Files\NVIDIA\CUDNN\v9.10\bin\cudnn64_9.dll" (
    echo Found: C:\Program Files\NVIDIA\CUDNN\v9.10\bin\cudnn64_9.dll
    set "FOUND=1"
    set "CUDNN_PATH=C:\Program Files\NVIDIA\CUDNN\v9.10\bin\cudnn64_9.dll"
    goto :found
)

REM Search in PATH
echo Searching in PATH...
where cudnn64_9.dll >nul 2>nul
if %ERRORLEVEL% equ 0 (
    for /f "tokens=*" %%a in ('where cudnn64_9.dll') do (
        echo Found in PATH: %%a
        set "FOUND=1"
        set "CUDNN_PATH=%%a"
        goto :found
    )
)

:found
if %FOUND% equ 1 (
    echo.
    echo cuDNN found: %CUDNN_PATH%
    echo.
    echo Copying to project...
    if not exist "libs" mkdir libs
    copy "%CUDNN_PATH%" "libs\cudnn64_9.dll" >nul
    if %ERRORLEVEL% equ 0 (
        echo cuDNN successfully copied to libs\cudnn64_9.dll
        exit /b 0
    ) else (
        echo Copy error
        exit /b 1
    )
) else (
    echo.
    echo cuDNN not found in system
    echo.
    echo Solutions:
    echo 1. Install NVIDIA cuDNN: https://developer.nvidia.com/cudnn
    echo 2. Extract cuDNN to: C:\Program Files\NVIDIA\CUDNN\v9.11\bin\
    echo 3. Work without cuDNN: set TONE_USE_GPU=false
    echo.
    echo Creating placeholder for continued work...
    if not exist "libs" mkdir libs
    echo # cuDNN placeholder - replace with real cudnn64_9.dll > libs\cudnn64_9.dll.txt
    echo Project ready to work (with GPU warnings)
    exit /b 0
)

echo.
if "%1" neq "silent" pause
