# Set working directory to project root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "  Pushing VANET AI Security System to GitHub" -ForegroundColor Green
Write-Host "  Target: https://github.com/faay-102/VANET.git" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Configuring remote URL..." -ForegroundColor Gray
git remote set-url origin https://github.com/faay-102/VANET.git

Write-Host "[2/4] Staging files..." -ForegroundColor Gray
git add .

Write-Host "[3/4] Creating commit..." -ForegroundColor Gray
git commit -m "feat: real-time interactive AI simulator with touch control, trained car dodge reactions, and authentic trust math"

Write-Host "[4/4] Pushing to main branch..." -ForegroundColor Green
git branch -M main
git push -u origin main

Write-Host ""
Write-Host "Push complete! Visit your repository at:" -ForegroundColor Green
Write-Host "https://github.com/faay-102/VANET" -ForegroundColor Cyan
