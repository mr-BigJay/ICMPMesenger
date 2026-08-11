#Requires -Version 3.0
<#
.SYNOPSIS
    Quick connectivity test to XuanIM server (192.168.152.2).

.DESCRIPTION
    Tests ping and TCP ports 11444 (client), 11443 (admin), 13911 (Padvish).
    Saves SEND-THIS-REPORT.txt for IT admin.

.EXAMPLE
    .\Test-XuanIM-Port.ps1 -SaveLog
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Server = "192.168.152.2",

    [Parameter(Mandatory = $false)]
    [string]$CenterName = "",

    [Parameter(Mandatory = $false)]
    [switch]$SaveLog
)

$ErrorActionPreference = 'Continue'

$ports = @(
    @{ Port = 11444; Label = "XuanIM client (XXD)" },
    @{ Port = 11443; Label = "XuanIM admin panel" },
    @{ Port = 13911; Label = "Padvish agent" }
)

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$computer  = $env:COMPUTERNAME
$user      = $env:USERNAME
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$reportDir = Join-Path $scriptDir "Reports"

$lines = New-Object System.Collections.Generic.List[string]

function Add-Line { param([string]$Text = "") $script:lines.Add($Text) }

Add-Line "=========================================="
Add-Line "  XUANIM QUICK CONNECTION TEST"
Add-Line "=========================================="
Add-Line "Time       : $timestamp"
Add-Line "Computer   : $computer"
Add-Line "User       : $user"
if ($CenterName) { Add-Line "Center     : $CenterName" }
Add-Line "Server IP  : $Server"
Add-Line "=========================================="
Add-Line ""

Write-Host ""
Write-Host "XuanIM Quick Connection Test" -ForegroundColor Yellow
Write-Host "Server: $Server"
Write-Host "From  : $computer ($user)"
if ($CenterName) { Write-Host "Center: $CenterName" }
Write-Host ""

# Ping
Add-Line "--- Ping ---"
Write-Host "--- Ping ---" -ForegroundColor Cyan
$pingOk = $false
$pingOutput = ping -n 4 $Server 2>&1 | Out-String
Write-Host $pingOutput
Add-Line $pingOutput.TrimEnd()

if ($pingOutput -match '(\d+)% loss') {
    $loss = $Matches[1]
    Add-Line "Packet loss: $loss%"
    if ($loss -eq "0") { $pingOk = $true }
}
if ($pingOutput -match 'Average = (\d+)ms') {
    Add-Line "Average latency: $($Matches[1]) ms"
}

Add-Line ""
Add-Line "--- TCP ports (Test-NetConnection) ---"
Write-Host "--- TCP ports ---" -ForegroundColor Cyan

$allPortsOk = $true
$xuanimClientOk = $false

foreach ($entry in $ports) {
    $port = $entry.Port
    $label = $entry.Label
    $ok = $false
    $detail = ""

    try {
        if (Get-Command Test-NetConnection -ErrorAction SilentlyContinue) {
            $r = Test-NetConnection -ComputerName $Server -Port $port -WarningAction SilentlyContinue
            $ok = [bool]$r.TcpTestSucceeded
            $detail = if ($ok) { "TcpTestSucceeded = True" } else { "TcpTestSucceeded = False" }
        } else {
            $client = New-Object System.Net.Sockets.TcpClient
            $async = $client.BeginConnect($Server, $port, $null, $null)
            $wait = $async.AsyncWaitHandle.WaitOne(3000, $false)
            if ($wait -and $client.Connected) { $ok = $true; $detail = "Connected" }
            else { $detail = "Timeout or refused" }
            $client.Close()
        }
    } catch {
        $detail = $_.Exception.Message
    }

    $status = if ($ok) { "OPEN" } else { "CLOSED" }
    $line = "Port $port ($label): $status  [$detail]"
    Add-Line $line

    $color = if ($ok) { "Green" } else { "Red" }
    Write-Host $line -ForegroundColor $color

    if ($port -eq 11444) { $xuanimClientOk = $ok }
    if (-not $ok -and $port -in 11443, 11444) { $allPortsOk = $false }
}

Add-Line ""
Add-Line "--- Summary ---"

if ($pingOk) {
    Add-Line "Ping: OK"
    Write-Host "Ping: OK" -ForegroundColor Green
} else {
    Add-Line "Ping: FAIL or blocked (TCP may still work)"
    Write-Host "Ping: FAIL or blocked" -ForegroundColor Yellow
}

if ($xuanimClientOk) {
    Add-Line "XuanIM (11444): READY - client can connect"
    Add-Line "Overall: GOOD"
    Write-Host ""
    Write-Host "XuanIM (11444): READY" -ForegroundColor Green
    Write-Host "Overall: GOOD" -ForegroundColor Green
} else {
    Add-Line "XuanIM (11444): NOT READY"
    if (-not $pingOk) {
        Add-Line "Overall: PROBLEM - check network"
    } else {
        Add-Line "Overall: WAITING - server may not have XuanIM installed yet, or firewall/service issue"
    }
    Write-Host ""
    Write-Host "XuanIM (11444): NOT READY" -ForegroundColor Red
    if ($pingOk) {
        Write-Host "Note: Ping OK but port closed = XuanIM not installed/running yet, or firewall." -ForegroundColor Yellow
    } else {
        Write-Host "Overall: PROBLEM - check network" -ForegroundColor Red
    }
}

Add-Line ""
Add-Line "Command used: Test-NetConnection $Server -Port 11444"
Add-Line "=========================================="

if ($SaveLog) {
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    $latestFile = Join-Path $reportDir "SEND-THIS-REPORT.txt"
    $archiveFile = Join-Path $reportDir ("XuanIM-test_{0}_{1:yyyyMMdd_HHmmss}.txt" -f $computer, (Get-Date))
    $text = $lines -join [Environment]::NewLine
    $text | Out-File -FilePath $latestFile -Encoding UTF8
    $text | Out-File -FilePath $archiveFile -Encoding UTF8

    Write-Host ""
    Write-Host "Report saved:" -ForegroundColor Cyan
    Write-Host $latestFile
    Write-Host "Send this file to IT admin." -ForegroundColor Gray

    try { Set-Clipboard -Value $latestFile } catch { }
    Start-Process explorer.exe -ArgumentList $reportDir
}

Write-Host ""
