# Network Connection Test (PowerShell)

Tests whether **this PC** can reach the central server (XuanIM / Padvish).

Default server: `192.168.152.2`

## Files

| File | Purpose |
|------|---------|
| `Test-ServerConnection.ps1` | Main script |
| `Run-ConnectionTest-ForColleague.bat` | **For colleagues** — one-click, auto report |
| `Run-ConnectionTest.bat` | General launcher |
| `COLLEAGUE-INSTRUCTIONS.txt` | Instructions for colleagues |
| `Reports/SEND-THIS-REPORT.txt` | Report to send (created after run) |

## Colleague workflow

1. Run `Run-ConnectionTest-ForColleague.bat`
2. Enter site/center name
3. Send `Reports/SEND-THIS-REPORT.txt` to IT admin

## PowerShell usage

```powershell
cd C:\Tools\NetworkTest
.\Test-ServerConnection.ps1 -SaveLog
```

Custom server:

```powershell
.\Test-ServerConnection.ps1 -Server 192.168.152.2 -CenterName "Site-1" -SaveLog
```

XuanIM ports only:

```powershell
.\Test-ServerConnection.ps1 -Ports 11444,11443 -SaveLog
```

## If execution is blocked

Run once in PowerShell as Administrator:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

## Default ports

| Port | Service |
|------|---------|
| 11444 | XuanIM client (XXD) |
| 11443 | XuanIM admin (HTTPS) |
| 13911 | Padvish agent |

## Reading results

| Output | Meaning |
|--------|---------|
| Port 11444 : **OK** | Messenger reachable from this PC |
| Port 11444 : **FAIL** | Firewall or routing problem |
| Ping **FAIL**, Port **OK** | Normal if ICMP is blocked; TCP works |

Run on **2-3 PCs per site** and compare reports.
