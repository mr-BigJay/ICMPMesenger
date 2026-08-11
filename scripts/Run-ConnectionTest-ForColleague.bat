@echo off
title Server Connection Test - 192.168.152.2

echo.
echo ========================================
echo   Server Connection Test
echo   Server: 192.168.152.2
echo ========================================
echo.
echo This test takes a few minutes. Please wait...
echo.

set /p CENTER=Enter site/center name (e.g. Site-1): 

echo.
echo Running tests...
echo.

if "%CENTER%"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-ServerConnection.ps1" -Server "192.168.152.2" -SaveLog
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-ServerConnection.ps1" -Server "192.168.152.2" -CenterName "%CENTER%" -SaveLog
)

echo.
echo ========================================
echo   Done!
echo.
echo   The Reports folder has opened.
echo   Send SEND-THIS-REPORT.txt to IT admin.
echo ========================================
echo.
pause
