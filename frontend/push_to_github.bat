@echo off
cd /d "%~dp0\.."
echo =========================================================
echo   Pushing VANET AI Security System to GitHub
echo   Target: https://github.com/faay-102/VANET.git
echo =========================================================

git remote set-url origin https://github.com/faay-102/VANET.git
git add .
git commit -m "feat: full Explainable AI VANET misbehavior detection, trust management & emergency priority system"
git branch -M main
git push -u origin main

pause
