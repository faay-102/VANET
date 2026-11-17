@echo off
cd /d "%~dp0\.."
echo =========================================================
echo   Pushing VANET AI Security System to GitHub
echo   Target: https://github.com/faay-102/VANET.git
echo =========================================================

git remote set-url origin https://github.com/faay-102/VANET.git
git add .
git commit -m "feat: unified orange theme, 5-tab bottom navigation, interactive test lab & solo vehicle simulator"
git branch -M main
git push -u origin main

pause
