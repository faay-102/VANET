# VANET Misbehavior Detection & Trust System Launcher
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Launching Full Application (Backend + Frontend)" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Test-Path "$scriptDir\backend") {
    $rootDir = $scriptDir
} elseif (Test-Path "$scriptDir\..\backend") {
    $rootDir = (Resolve-Path "$scriptDir\..").Path
} else {
    $rootDir = $scriptDir
}

# 1. Start Backend in a new PowerShell window
Write-Host "`n[1/2] Starting FastAPI Backend on http://127.0.0.1:8000 ..." -ForegroundColor Yellow
$backendCmd = "Set-Location '$rootDir\backend'; if (Test-Path '.\venv\Scripts\Activate.ps1') { .\venv\Scripts\Activate.ps1 }; uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd

# 2. Start Frontend in a new PowerShell window
Write-Host "[2/2] Starting Flutter Dashboard Client (Chrome) ..." -ForegroundColor Yellow
$frontendCmd = "Set-Location '$rootDir\frontend'; flutter run -d chrome"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd

Write-Host "`nBoth processes have been started in separate windows!" -ForegroundColor Green
Write-Host "Backend API docs: http://127.0.0.1:8000/docs" -ForegroundColor White
