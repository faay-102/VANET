@echo off
echo =========================================================
echo   [1/3] Freeing Locks & Cleaning Gradle Cache...
echo =========================================================
taskkill /F /IM java.exe 2>nul
taskkill /F /IM ninja.exe 2>nul
taskkill /F /IM cmake.exe 2>nul

if exist "%USERPROFILE%\.gradle\caches\8.14\transforms" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches\8.14\transforms" 2>nul
)

cd /d "%~dp0"
call flutter pub get

echo.
echo =========================================================
echo   [2/3] Compiling Android APK...
echo =========================================================
call flutter build apk --debug

echo.
echo =========================================================
echo   [3/3] Locating and Preparing APK...
echo =========================================================
set APK_PATH=
for /r "%~dp0" %%F in (*.apk) do (
    set APK_PATH=%%F
)

if defined APK_PATH (
    echo.
    echo =========================================================
    echo   BUILD SUCCESSFUL!
    echo   Found: %APK_PATH%
    echo   Copying to your main folder as:
    echo   %~dp0..\VANET_Security_App.apk
    echo =========================================================
    copy "%APK_PATH%" "%~dp0..\VANET_Security_App.apk" >nul
    echo.
    echo Opening folder in Windows Explorer with your APK selected...
    explorer.exe /select,"%~dp0..\VANET_Security_App.apk"
)

pause
