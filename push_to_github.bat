@echo off
cd /d "%~dp0"

echo =========================================================
echo   [1/3] Staging updated Colab notebook, backend and guides...
echo =========================================================
git add colab/VANET_Misbehavior_Detection_Colab.ipynb
git add VANET_Misbehavior_Detection_Colab.ipynb
git add backend/app/routes/predictions.py
git add backend/scripts/simulate_ml.py
git add -A

echo.
echo =========================================================
echo   [2/3] Committing changes...
echo =========================================================
git commit -m "docs: align README with viva guide, fix A* heuristic admissibility, and update endpoint specifications"

echo.
echo =========================================================
echo   [3/3] Pushing to GitHub remote (origin/main)...
echo =========================================================
git push origin main

echo.
echo =========================================================
echo   SUCCESS! Pushed latest changes to GitHub:
echo   https://github.com/faay-102/VANET
echo =========================================================
pause
