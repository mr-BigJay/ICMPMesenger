#Requires -Version 3.0
<#
.SYNOPSIS
    Test network connectivity from this PC to the central server.

.PARAMETER Server
    Server IP. Default: 192.168.152.2

.PARAMETER CenterName
    Optional center/site name (shown in report).

.PARAMETER SaveLog
    Save report file (enabled by default in colleague launcher).

.EXAMPLE
    .\Test-ServerConnection.ps1

.EXAMPLE
    .\Test-ServerConnection.ps1 -CenterName "مرکز 1" -SaveLog
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Server = "192.168.152.2",

    [Parameter(Mandatory = $false)]
    [string]$CenterName = "",

    [Parameter(Mandatory = $false)]
    [int[]]$Ports = @(11444, 11443, 13911),

    [Parameter(Mandatory = $false)]
    [int]$PingCount = 4,

    [Parameter(Mandatory = $false)]
    [switch]$SaveLog
)

$ErrorActionPreference = 'Continue'

$reportLines = New-Object System.Collections.Generic.List[string]

function Add-Report {
    param([string]$Line = "")
    $script:reportLines.Add($Line)
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=== $Title ===") -ForegroundColor Cyan
    Add-Report ""
    Add-Report "=== $Title ==="
}

function Write-Result {
    param(
        [string]$Label,
        [bool]$Ok,
        [string]$Detail = ""
    )
    $status = if ($Ok) { "OK" } else { "FAIL" }
    $color  = if ($Ok) { "Green" } else { "Red" }
    $line   = "  $Label : $status"
    if ($Detail) { $line += "  ($Detail)" }
    Write-Host $line -ForegroundColor $color
    Add-Report $line
}

# --- Header ---
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$computer  = $env:COMPUTERNAME
$user      = $env:USERNAME
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$reportDir = Join-Path $scriptDir "Reports"

Add-Report "=========================================="
Add-Report "  SERVER CONNECTION TEST REPORT"
Add-Report "  گزارش تست ارتباط با سرور"
Add-Report "=========================================="
Add-Report "Time       : $timestamp"
Add-Report "Computer   : $computer"
Add-Report "User       : $user"
if ($CenterName) { Add-Report "Center     : $CenterName" }
Add-Report "Server IP  : $Server"
Add-Report "Ports      : $($Ports -join ', ')"
Add-Report "=========================================="

Write-Host ""
Write-Host "Server Connection Test / تست ارتباط با سرور" -ForegroundColor Yellow
Write-Host "Time    : $timestamp"
Write-Host "From    : $computer ($user)"
if ($CenterName) { Write-Host "Center  : $CenterName" }
Write-Host "Target  : $Server"
Write-Host "Ports   : $($Ports -join ', ')"

$summary = [ordered]@{
    PingOk      = $false
    PingLoss    = "N/A"
    PingAvgMs   = "N/A"
    Ports       = @{}
    Overall     = $false
    ResolveOk   = $false
}

# --- 1. DNS ---
Write-Section "1. Name resolution / تبدیل نام به IP"
try {
    $resolved = [System.Net.Dns]::GetHostAddresses($Server) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
    if ($resolved) {
        $summary.ResolveOk = $true
        Write-Result -Label "Resolve $Server" -Ok $true -Detail ($resolved[0].IPAddressToString)
    } else {
        Write-Result -Label "Resolve $Server" -Ok $false -Detail "No IPv4 address"
    }
} catch {
    Write-Result -Label "Resolve $Server" -Ok $false -Detail $_.Exception.Message
}

# --- 2. Ping ---
Write-Section "2. Ping (ICMP) / پینگ"
$pingOk = $false
try {
    $ping = New-Object System.Net.NetworkInformation.Ping
    $reply = $ping.Send($Server, 3000)
    if ($reply.Status -eq 'Success') {
        $pingOk = $true
        Write-Result -Label "Ping $Server" -Ok $true -Detail "$($reply.RoundtripTime) ms"
    } else {
        Write-Result -Label "Ping $Server" -Ok $false -Detail "$($reply.Status) (TCP may still work)"
    }
} catch {
    Write-Result -Label "Ping $Server" -Ok $false -Detail "$($_.Exception.Message) (TCP may still work)"
}

$pingCmd = ping -n $PingCount $Server 2>&1 | Out-String
Write-Host $pingCmd
Add-Report "--- ping output ---"
Add-Report $pingCmd.TrimEnd()

if ($pingCmd -match '(\d+)% loss') {
    $summary.PingLoss = "$($Matches[1])%"
    if ([int]$Matches[1] -eq 0) { $pingOk = $true }
}
if ($pingCmd -match 'Average = (\d+)ms') {
    $summary.PingAvgMs = "$($Matches[1]) ms"
}
$summary.PingOk = $pingOk

# --- 3. TCP ports ---
Write-Section "3. TCP ports / پورت‌های TCP"
$allPortsOk = $true
foreach ($port in $Ports) {
    $portOk = $false
    $detail = ""
    try {
        if (Get-Command Test-NetConnection -ErrorAction SilentlyContinue) {
            $tnc = Test-NetConnection -ComputerName $Server -Port $port -WarningAction SilentlyContinue -ErrorAction Stop
            $portOk = [bool]$tnc.TcpTestSucceeded
            $detail = if ($portOk) { "Open" } else { "Closed or filtered" }
        } else {
            $client = New-Object System.Net.Sockets.TcpClient
            $async  = $client.BeginConnect($Server, $port, $null, $null)
            $wait   = $async.AsyncWaitHandle.WaitOne(3000, $false)
            if ($wait -and $client.Connected) {
                $portOk = $true
                $detail = "Open"
            } else {
                $detail = "Timeout or refused"
            }
            $client.Close()
        }
    } catch {
        $detail = $_.Exception.Message
    }

    $label = switch ($port) {
        11444 { "Port $port (XuanIM client/XXD)" }
        11443 { "Port $port (XuanIM admin/HTTPS)" }
        13911 { "Port $port (Padvish agent)" }
        default { "Port $port" }
    }
    Write-Result -Label $label -Ok $portOk -Detail $detail
    $summary.Ports[$port] = $portOk
    if (-not $portOk) { $allPortsOk = $false }
}

# --- 4. Traceroute ---
Write-Section "4. Traceroute / مسیر شبکه"
$tracertCmd = tracert -d -h 20 $Server 2>&1 | Out-String
Write-Host $tracertCmd
Add-Report "--- tracert output ---"
Add-Report $tracertCmd.TrimEnd()

# --- 5. Summary ---
Write-Section "5. Summary / جمع‌بندی"

$verdict = if ($allPortsOk) { "GOOD - Ready for messenger" } else { "PROBLEM - Fix network/firewall" }
$verdictFa = if ($allPortsOk) { "خوب - آماده برای مسنجر" } else { "مشکل - شبکه/فایروال را بررسی کنید" }

Add-Report ""
Add-Report "--- FINAL SUMMARY / جمع‌بندی نهایی ---"
Add-Report "Ping OK          : $($summary.PingOk)"
Add-Report "Packet loss      : $($summary.PingLoss)"
Add-Report "Average latency  : $($summary.PingAvgMs)"
foreach ($port in $Ports) {
    $pStatus = if ($summary.Ports[$port]) { "OPEN" } else { "FAIL" }
    Add-Report "Port $port         : $pStatus"
}
Add-Report "Overall          : $verdict"
Add-Report "وضعیت کلی        : $verdictFa"
Add-Report ""

$summary.Overall = $allPortsOk

if ($summary.Ports[11444] -eq $true) {
    Write-Host "  XuanIM (11444): Ready" -ForegroundColor Green
    Add-Report "XuanIM (11444)   : Ready"
} else {
    Write-Host "  XuanIM (11444): NOT reachable" -ForegroundColor Red
    Add-Report "XuanIM (11444)   : NOT reachable"
}

if ($summary.Ports[13911] -eq $true) {
    Write-Host "  Padvish (13911): Reachable" -ForegroundColor Green
    Add-Report "Padvish (13911)  : Reachable"
} elseif ($summary.Ports.Contains(13911)) {
    Write-Host "  Padvish (13911): NOT reachable" -ForegroundColor Yellow
    Add-Report "Padvish (13911)  : NOT reachable"
}

if (-not $pingOk -and $allPortsOk) {
    $note = "Ping failed but TCP ports OPEN - normal if ICMP blocked."
    Write-Host "  Note: $note" -ForegroundColor Yellow
    Add-Report "Note: $note"
}

Write-Host ""
if ($allPortsOk) {
    Write-Host "  OVERALL: GOOD" -ForegroundColor Green
} else {
    Write-Host "  OVERALL: PROBLEM" -ForegroundColor Red
}

# --- Save report ---
if ($SaveLog) {
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }

    $safeCenter = if ($CenterName) { $CenterName -replace '[^\w\-]', '_' } else { "no-center" }
    $reportFile = Join-Path $reportDir ("REPORT_{0}_{1}_{2:yyyyMMdd_HHmmss}.txt" -f $computer, $safeCenter, (Get-Date))
    $latestFile = Join-Path $reportDir "SEND-THIS-REPORT.txt"

    $reportText = ($reportLines -join [Environment]::NewLine)
    $reportText | Out-File -FilePath $reportFile -Encoding UTF8
    $reportText | Out-File -FilePath $latestFile -Encoding UTF8

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  REPORT SAVED / گزارش ذخیره شد" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  File for your manager:" -ForegroundColor Cyan
    Write-Host "  $latestFile" -ForegroundColor White
    Write-Host ""
    Write-Host "  Please send this file to your IT admin." -ForegroundColor Gray
    Write-Host "  لطفاً این فایل را برای مدیر IT بفرستید." -ForegroundColor Gray
    Write-Host ""

    try {
        Set-Clipboard -Value $latestFile
        Write-Host "  (Report path copied to clipboard)" -ForegroundColor Gray
    } catch {
        # Clipboard not available on all systems
    }

    Start-Process explorer.exe -ArgumentList $reportDir
}

Write-Host ""
