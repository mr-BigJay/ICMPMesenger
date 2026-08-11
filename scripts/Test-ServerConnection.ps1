#Requires -Version 3.0
<#
.SYNOPSIS
    Test network connectivity from this PC to a server (XuanIM, Padvish, etc.)

.DESCRIPTION
    Checks ping, TCP ports, traceroute, and optionally saves a report.
    Run on each center/client PC to verify reachability to the central server.

.PARAMETER Server
    Server IP address or hostname (required).

.PARAMETER Ports
    TCP ports to test. Default: 11444, 11443 (XuanIM), 13911 (Padvish).

.PARAMETER PingCount
    Number of ping packets. Default: 4.

.PARAMETER SaveLog
    Save output to a log file in the same folder as this script.

.EXAMPLE
    .\Test-ServerConnection.ps1 -Server 192.168.1.10

.EXAMPLE
    .\Test-ServerConnection.ps1 -Server 10.0.0.5 -Ports 11444,443 -SaveLog
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Server,

    [Parameter(Mandatory = $false)]
    [int[]]$Ports = @(11444, 11443, 13911),

    [Parameter(Mandatory = $false)]
    [int]$PingCount = 4,

    [Parameter(Mandatory = $false)]
    [switch]$SaveLog
)

$ErrorActionPreference = 'Continue'

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=== $Title ===") -ForegroundColor Cyan
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
}

# --- Header ---
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$computer  = $env:COMPUTERNAME
$user      = $env:USERNAME

Write-Host ""
Write-Host "Server Connection Test / تست ارتباط با سرور" -ForegroundColor Yellow
Write-Host "Time    : $timestamp"
Write-Host "From    : $computer ($user)"
Write-Host "Target  : $Server"
Write-Host "Ports   : $($Ports -join ', ')"

$summary = [ordered]@{
    PingOk   = $false
    Ports    = @{}
    Overall  = $false
}

# --- 1. DNS / name resolution ---
Write-Section "1. Name resolution / تبدیل نام به IP"
try {
    $resolved = [System.Net.Dns]::GetHostAddresses($Server) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
    if ($resolved) {
        Write-Result -Label "Resolve $Server" -Ok $true -Detail ($resolved[0].IPAddressToString)
        if ($resolved.Count -gt 1) {
            Write-Host "  All IPv4: $($resolved.IPAddressToString -join ', ')" -ForegroundColor Gray
        }
    } else {
        Write-Result -Label "Resolve $Server" -Ok $false -Detail "No IPv4 address"
    }
} catch {
    Write-Result -Label "Resolve $Server" -Ok $false -Detail $_.Exception.Message
}

# --- 2. Ping ---
Write-Section "2. Ping (ICMP) / پینگ"
$pingOk = $false
$pingDetail = ""
try {
    $ping = New-Object System.Net.NetworkInformation.Ping
    $reply = $ping.Send($Server, 3000)
    if ($reply.Status -eq 'Success') {
        $pingOk = $true
        $pingDetail = "$($reply.RoundtripTime) ms (single probe)"
        Write-Result -Label "Ping $Server" -Ok $true -Detail $pingDetail
    } else {
        $pingDetail = $reply.Status.ToString()
        Write-Result -Label "Ping $Server" -Ok $false -Detail "$pingDetail (TCP may still work)"
    }
} catch {
    $pingDetail = $_.Exception.Message
    Write-Result -Label "Ping $Server" -Ok $false -Detail "$pingDetail (TCP may still work)"
}

Write-Host "  Extended ping ($PingCount packets):" -ForegroundColor Gray
$pingCmd = ping -n $PingCount $Server 2>&1 | Out-String
Write-Host $pingCmd

if ($pingCmd -match '(\d+)% loss') {
    $loss = [int]$Matches[1]
    if ($loss -eq 0) { $pingOk = $true }
    elseif ($loss -lt 100) {
        Write-Host "  Warning: $loss% packet loss" -ForegroundColor Yellow
    }
}
if ($pingCmd -match 'Average = (\d+)ms') {
    Write-Host "  Average latency: $($Matches[1]) ms" -ForegroundColor Gray
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
            $detail = if ($portOk) { "TcpTestSucceeded" } else { "Closed or filtered" }
        } else {
            $client = New-Object System.Net.Sockets.TcpClient
            $async  = $client.BeginConnect($Server, $port, $null, $null)
            $wait   = $async.AsyncWaitHandle.WaitOne(3000, $false)
            if ($wait -and $client.Connected) {
                $portOk = $true
                $detail = "Connected"
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
        445   { "Port $port (SMB)" }
        default { "Port $port" }
    }
    Write-Result -Label $label -Ok $portOk -Detail $detail
    $summary.Ports[$port] = $portOk
    if (-not $portOk) { $allPortsOk = $false }
}

# --- 4. Traceroute ---
Write-Section "4. Traceroute / مسیر شبکه"
Write-Host "  tracert -d -h 20 $Server" -ForegroundColor Gray
tracert -d -h 20 $Server

# --- 5. Summary ---
Write-Section "5. Summary / جمع‌بندی"
$xuanimOk = ($summary.Ports[11444] -eq $true)
$padvishOk = ($summary.Ports[13911] -eq $true)

if ($xuanimOk) {
    Write-Host "  XuanIM (11444): Ready for client connection" -ForegroundColor Green
} elseif ($summary.Ports.Contains(11444)) {
    Write-Host "  XuanIM (11444): NOT reachable - check firewall on server and this PC" -ForegroundColor Red
}

if ($padvishOk) {
    Write-Host "  Padvish (13911): Reachable" -ForegroundColor Green
} elseif ($summary.Ports.Contains(13911)) {
    Write-Host "  Padvish (13911): NOT reachable" -ForegroundColor Yellow
}

if (-not $pingOk -and $allPortsOk) {
    Write-Host "  Note: Ping failed but TCP ports are OPEN - this is normal if ICMP is blocked." -ForegroundColor Yellow
}

$summary.Overall = $allPortsOk
if ($summary.Overall) {
    Write-Host ""
    Write-Host "  OVERALL: Connection looks GOOD for configured ports." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  OVERALL: Some ports FAILED - fix firewall/routing before rollout." -ForegroundColor Red
}

# --- Save log ---
if ($SaveLog) {
    $logDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
    $logFile = Join-Path $logDir ("connection-test_{0}_{1:yyyyMMdd_HHmmss}.log" -f $computer, (Get-Date))
    $logText = @"
Server Connection Test
Time: $timestamp
From: $computer ($user)
Target: $Server
Ports: $($Ports -join ', ')
Ping OK: $($summary.PingOk)
Port results: $(($summary.Ports.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', ')
Overall: $($summary.Overall)

--- ping ---
$pingCmd
"@
    $logText | Out-File -FilePath $logFile -Encoding UTF8
    Write-Host ""
    Write-Host "  Log saved: $logFile" -ForegroundColor Gray
}

Write-Host ""
