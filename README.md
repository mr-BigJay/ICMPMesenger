# ICMPMesenger / Jay Messenger

Internal messenger project based on [XuanIM](https://github.com/xuanim/xuanim) (open source, AGPL-3.0).

## For IT admin (you)

| Task | Location |
|------|----------|
| **Download Windows client installer** | GitHub → Actions → *Build Jay Messenger (Windows)* → Artifacts |
| **Network test scripts** | [`scripts/`](scripts/) |
| **Customize app name / UI text** | [`custom/branding/`](custom/branding/) |
| **Install server (XXB/XXD)** | Official XuanIM one-click on `192.168.152.2` |

## Quick start — client installer (no dev tools on your PC)

1. Go to **Actions** → **Build Jay Messenger (Windows)** → **Run workflow**
2. Wait ~30–60 minutes (first build)
3. Download artifact **JayMessenger-Windows-Installer**
4. Install on client PCs
5. Set server: `192.168.152.2:11444`

## Quick start — network test (colleagues)

Run `scripts/Run-Test-XuanIM-ForColleague.bat` and send `Reports/SEND-THIS-REPORT.txt` to IT.

## Repository layout

```
custom/          Branding + apply script (CI patches upstream XuanIM)
scripts/         PowerShell network test tools
.github/         Windows installer build workflow
```

Upstream XuanIM source is **not** stored in this repo (518MB). It is cloned during CI build.

## Internal use only

Not for commercial distribution. AGPL-3.0 applies to XuanIM components.
