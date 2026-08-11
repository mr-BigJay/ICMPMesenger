@echo off
chcp 65001 >nul
title تست ارتباط با سرور - 192.168.152.2

echo.
echo ========================================
echo   تست ارتباط با سرور
echo   Server: 192.168.152.2
echo ========================================
echo.
echo این تست چند دقیقه طول می‌کشد. صبر کنید...
echo.

set /p CENTER=نام مرکز را وارد کنید (مثلا مرکز 1): 

echo.
echo در حال تست...
echo.

if "%CENTER%"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-ServerConnection.ps1" -Server "192.168.152.2" -SaveLog
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-ServerConnection.ps1" -Server "192.168.152.2" -CenterName "%CENTER%" -SaveLog
)

echo.
echo ========================================
echo   تمام شد!
echo.
echo   پوشه Reports باز شد.
echo   فایل SEND-THIS-REPORT.txt را برای
echo   مدیر IT بفرستید (ایمیل / تلگرام / ...)
echo ========================================
echo.
pause
