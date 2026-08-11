@echo off
chcp 65001 >nul
title Server Connection Test

echo.
echo ========================================
echo   Server Connection Test
echo   Default server: 192.168.152.2
echo ========================================
echo.

set /p SERVER=Server IP [Enter = 192.168.152.2]: 
if "%SERVER%"=="" set SERVER=192.168.152.2

set /p CENTER=Center name (optional): 

echo.
echo Testing %SERVER% ...
echo.

if "%CENTER%"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-ServerConnection.ps1" -Server "%SERVER%" -SaveLog
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-ServerConnection.ps1" -Server "%SERVER%" -CenterName "%CENTER%" -SaveLog
)

echo.
pause
