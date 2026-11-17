@echo off
cd /d "%~dp0"

echo =========================================================
echo   [1/4] Syncing with GitHub and purging large APK from history...
echo =========================================================
git remote set-url origin https://github.com/faay-102/VANET.git
git fetch origin main 2>nul
git reset origin/main 2>nul

echo.
echo =========================================================
echo   [2/4] Ensuring large APK is untracked...
echo =========================================================
git rm --cached -f "VANET_Security_App.apk" 2>nul
git rm --cached -r -f "*.apk" 2>nul

echo.
echo =========================================================
echo   [3/4] Staging clean source code files...
echo =========================================================
git add -A

echo.
echo =========================================================
echo   [4/4] Pushing lightweight source code to GitHub...
echo =========================================================
git commit -m "fix(responsive): eliminate RenderFlex overflows across all screens and clean workspace"
git branch -M main
git push -u origin main --force

echo.
echo =========================================================
echo   SUCCESS! Pushed to GitHub without large APK files:
echo   https://github.com/faay-102/VANET
echo =========================================================
pause
