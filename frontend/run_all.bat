@echo off
title VANET System Launcher
echo ========================================================
echo   Launching VANET Misbehavior Detection & Trust System
echo ========================================================
echo.

if exist "%~dp0backend" (
    set "ROOT_DIR=%~dp0"
) else (
    set "ROOT_DIR=%~dp0..\"
)

echo [1/2] Starting FastAPI Backend on http://127.0.0.1:8000 ...
start "VANET Backend (FastAPI)" cmd /k "cd /d "%ROOT_DIR%backend" && (if exist venv\Scripts\activate.bat call venv\Scripts\activate.bat) && uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload"

echo [2/2] Starting Flutter Dashboard Client ...
start "VANET Frontend (Flutter)" cmd /k "cd /d "%ROOT_DIR%frontend" && flutter run -d chrome"

echo.
echo ========================================================
echo Both Backend and Frontend are launching in separate windows!
echo - Backend API Docs: http://127.0.0.1:8000/docs
echo - Frontend: Chrome Web Dashboard
echo ========================================================
pause
