@echo off
chcp 65001 >nul
title Server Connection Test

echo.
echo ========================================
echo   Server Connection Test
echo   تست ارتباط با سرور
echo ========================================
echo.

set /p SERVER=Enter server IP (مثلا 192.168.1.10): 
if "%SERVER%"=="" (
    echo Error: IP is required.
    pause
    exit /b 1
)

echo.
echo Testing connection to %SERVER% ...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-ServerConnection.ps1" -Server "%SERVER%" -SaveLog

echo.
pause
