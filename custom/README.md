# Jay Messenger customizations

This folder contains **your branding and settings** applied on top of the official
[XuanIM open-source](https://github.com/xuanim/xuanim) client at build time.

You do **not** need Node.js or Git on your PC. GitHub Actions builds the Windows
installer for you.

## What gets customized

| File | Purpose |
|------|---------|
| `branding/package.overrides.json` | App name: **Jay Messenger** |
| `branding/lang-config.ts` | Default UI language: **English** |
| `branding/en-overrides.json` | Label overrides (login, send, etc.) |
| `apply-customizations.mjs` | Script used in CI to patch upstream source |

## How to get the Windows installer

1. Push changes to GitHub (or ask your developer to push).
2. Open the repo on GitHub → **Actions** tab.
3. Run workflow **"Build Jay Messenger (Windows)"** (or wait for auto-run on push).
4. When finished, open the run → **Artifacts** → download **JayMessenger-Windows-Installer**.
5. Copy the `.exe` to client PCs and install.

## How to change the app name or texts

Edit files in `custom/branding/` and push to GitHub. The next workflow run produces a new installer.

### Persian (fa-ir) — next step

Full Persian UI requires adding `fa-ir.json` and registering it in `lang-config.ts`.
Ask your developer to add this in a follow-up change.

## Server settings (after install)

Point the client to your server:

- **Server IP:** `192.168.152.2`
- **Port:** `11444` (after XuanIM server is installed on the server machine)

Client branding is built here; **server (XXB/XXD)** is still installed separately using the
official XuanIM Windows one-click package on `192.168.152.2`.

## License

Based on XuanIM (AGPL-3.0). Internal use only. See upstream `LICENSE`.
