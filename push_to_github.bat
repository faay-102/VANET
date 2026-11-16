@echo off
cd /d "%~dp0"
echo =========================================================
echo   Pushing VANET AI Security System to GitHub
echo   Target: https://github.com/faay-102/VANET.git
echo =========================================================

echo.
echo [1/4] Checking remote configuration...
git remote set-url origin https://github.com/faay-102/VANET.git

echo.
echo [2/4] Staging modified and new files...
git add .

echo.
echo [3/4] Committing changes...
git commit -m "feat: full Explainable AI VANET misbehavior detection, trust management & emergency priority system"

echo.
echo [4/4] Pushing to main branch...
git branch -M main
git push -u origin main

echo.
echo =========================================================
echo   Push complete! Check your repository:
echo   https://github.com/faay-102/VANET
echo =========================================================
pause
