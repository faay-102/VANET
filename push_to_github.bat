@echo off
cd /d "%~dp0"

echo =========================================================
echo   [1/3] Staging updated Colab notebook, backend and guides...
echo =========================================================
git add colab/VANET_Misbehavior_Detection_Colab.ipynb
git add backend/app/routes/
git add backend/app/services/
git add frontend/lib/core/constants/api_endpoints.dart
git add README.md
git add .gitignore
git add check_routing.py
git add push_to_github.bat

echo.
echo =========================================================
echo   [1.5/3] Inspecting Staged Changes (Status & Diff Stat)...
echo =========================================================
git status --short
git diff --cached --stat

echo.
echo =========================================================
echo   [2/3] Committing changes...
echo =========================================================
git commit -m "feat(core): harden trust engine, emergency routing & XAI; document trust poisoning limitation & update README"

echo.
echo =========================================================
echo   [3/3] Pushing to GitHub remote (origin/main)...
echo =========================================================
git push origin main
if %ERRORLEVEL% equ 0 (
    echo.
    echo =========================================================
    echo   SUCCESS! Pushed latest changes to GitHub:
    echo   https://github.com/faay-102/VANET
    echo =========================================================
) else (
    echo.
    echo =========================================================
    echo   ERROR: Git push failed! Please check your network or branch.
    echo =========================================================
)
pause
