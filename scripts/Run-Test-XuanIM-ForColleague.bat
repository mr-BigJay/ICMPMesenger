@echo off
title XuanIM Connection Test - 192.168.152.2

echo.
echo ========================================
echo   XuanIM Quick Connection Test
echo   Server: 192.168.152.2
echo   Port:   11444 (and 11443, 13911)
echo ========================================
echo.
echo Please wait...
echo.

set /p CENTER=Enter site name (e.g. Site-1): 

echo.

if "%CENTER%"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-XuanIM-Port.ps1" -SaveLog
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-XuanIM-Port.ps1" -CenterName "%CENTER%" -SaveLog
)

echo.
echo ========================================
echo   Done!
echo   Send Reports\SEND-THIS-REPORT.txt
echo   to your IT admin.
echo ========================================
echo.
pause
