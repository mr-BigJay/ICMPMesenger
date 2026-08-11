# تست ارتباط شبکه (PowerShell)

اسکریپت برای تست اینکه **این کامپیوتر** به **سرور مرکزی** (XuanIM / پادویش) می‌رسد یا نه.

## فایل‌ها

| فایل | کاربرد |
|------|--------|
| `Test-ServerConnection.ps1` | اسکریپت اصلی |
| `Run-ConnectionTest.bat` | اجرای ساده با دابل‌کلیک |

## روش ۱: دابل‌کلیک (ساده)

1. هر دو فایل را در یک پوشه کپی کن (مثلاً `C:\Tools\NetworkTest\`)
2. `Run-ConnectionTest.bat` را اجرا کن
3. IP سرور را وارد کن
4. نتیجه را بخوان؛ لاگ در همان پوشه ذخیره می‌شود

## روش ۲: PowerShell

```powershell
cd C:\Tools\NetworkTest
.\Test-ServerConnection.ps1 -Server 192.168.1.10
```

با ذخیره لاگ:

```powershell
.\Test-ServerConnection.ps1 -Server 192.168.1.10 -SaveLog
```

فقط پورت‌های XuanIM:

```powershell
.\Test-ServerConnection.ps1 -Server 192.168.1.10 -Ports 11444,11443
```

## اگر اجرا block شد

یک بار در PowerShell **Run as Administrator**:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

## پورت‌های پیش‌فرض

| پورت | سرویس |
|------|--------|
| 11444 | XuanIM کلاینت (XXD) |
| 11443 | XuanIM پنل ادمین |
| 13911 | پادویش (agent) |

## خواندن نتیجه

| پیام | معنی |
|------|------|
| Port 11444 : **OK** | مسنجر از این PC به سرور می‌رسد |
| Port 11444 : **FAIL** | فایروال یا مسیر شبکه مشکل دارد |
| Ping **FAIL** ولی Port **OK** | طبیعی است؛ ICMP بسته است ولی TCP باز است |

## توصیه

این اسکریپت را روی **هر مرکز** (۲–۳ PC از هر سایت) اجرا کن و خروجی را مقایسه کن.
