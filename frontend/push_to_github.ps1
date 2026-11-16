$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptDir "..")

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "  Pushing VANET AI Security System to GitHub" -ForegroundColor Green
Write-Host "  Target: https://github.com/faay-102/VANET.git" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Cyan

git remote set-url origin https://github.com/faay-102/VANET.git
git add .
git commit -m "feat: full Explainable AI VANET misbehavior detection, trust management & emergency priority system"
git branch -M main
git push -u origin main

Write-Host "Push complete! Visit your repository at: https://github.com/faay-102/VANET" -ForegroundColor Green
