@echo off
REM Convenience script to serve DevTest documentation locally on Windows

setlocal

echo 🚀 Starting DevTest Documentation Server...
echo 📁 Project: %~dp0..
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Python is required but not found
    echo 💡 Please install Python and try again
    echo 💡 Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Change to project root directory
cd /d "%~dp0.."

REM Run the documentation server
python scripts/serve_docs.py %*

pause
