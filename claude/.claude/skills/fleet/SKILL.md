---
name: fleet
description: Use when a task involves any of Pablo's machines — Buster, Bugs, Silvester, Zorak, Blusa.Cloud, Dokploy, Hermes, Taz, LOLA, Tweety, Marvin, Riki, Mama, devbox, Nuno — or remote access over SSH, Tailscale, or ZeroTier (checking logs, deploying, restarting services, copying files on a remote host, Noctua sensors, *.blusa.cloud apps).
allowed-tools: Bash(ssh:*), Bash(scp:*), Bash(tailscale:*)
---

# Fleet

Pablo's personal fleet: laptops, servers, and Noctua edge sensors, reachable over Tailscale (`100.x` IPs) and/or ZeroTier (`10.147.18.x`, domain `*.odinedge.xyz`). Machine names follow cartoon characters (Looney Tunes & co.) — a new host named after one is probably Pablo's.

## Golden rule: verify before connecting

The inventory below says *what each machine is*. IPs and online state must be verified live before connecting:

- `tailscale status` — live IPs and online/offline state of Tailscale machines
- `~/.ssh/config` — existing aliases (Noctua sensors + blusa.cloud)

If live data contradicts a table below, trust the live data and offer to update this skill.

## Inventory

Default SSH user: `blusa` (exceptions noted). Last validated: 2026-09-01.

### Laptops

| Name | HW / OS | Network / IP | Purpose |
|---|---|---|---|
| Buster (`buster-bunny`) | MacBook Pro, macOS | TS `100.77.231.63` + ZT | General + mobile dev — Pablo's usual local machine. **Dev completo desde 2026-09-03**: gh CLI autenticado como `blusa` (credential helper de git, refrescable máquina-a-máquina: `gh auth token` en Taz \| `gh auth login --with-token`), node 26 + npm, uv, Claude Code, EXPO_TOKEN en `~/.expo-token.env`, skills de `~/.claude/skills` (sincronizar a mano si se editan en Taz). **mongod (brew, 7.0) para tests del backend**: corre como servicio de brew, pero por SSH `brew services start` deja el job cargado sin lanzarlo — hace falta `launchctl kickstart -k gui/$(id -u)/homebrew.mxcl.mongodb-community@7.0`. Si crashea con "Too many open files" es que el límite del dominio launchd volvió a 256 (pasa tras reboot hasta que se instale `/Library/LaunchDaemons/limit.maxfiles.plist`, staged en `/tmp` el 2026-09-03; fallback: `ulimit -n 10240 && mongod --config /opt/homebrew/etc/mongod.conf --fork`). Shells no-interactivos: PATH de Homebrew solo con `zsh -lc`; sin agente SSH de 1Password fuera de la sesión gráfica |
| Bugs | ThinkPad P14s, Win 11 | TS `100.105.30.76` + ZT | Spinlock modern apps. No SSH server yet (setup pending) |
| Silvester | HP EliteBook, Win 10 | TS (IP TBC — not in current tailnet device list) | Spinlock legacy apps. No SSH server yet |
| Tweety | Windows | TS `100.112.179.45` | Runs T3 Code (desktop app, auto-start after reboot; exposed at `https://tweety.tail32621d.ts.net/`). No SSH |
| Marvin | Windows | TS `100.77.55.34` | Seen in tailnet 2026-09-01; purpose TBC. No SSH |

### Servers / workstations

| Name | Role | IP (Tailscale) | Notes |
|---|---|---|---|
| Zorak | Unraid server + personal NAS | `100.78.112.90` | Exit node; hosts the Blusa.Cloud and Hermes VMs. SSH port 22 refused as of 2026-07-03 (likely disabled in Unraid settings) — use the Unraid web UI, or enable SSH first; user likely `root` (Unraid) |
| Blusa.Cloud | Dokploy PaaS (VM on Zorak) | `100.95.237.71` | Apps deployed at `*.blusa.cloud`; ssh alias `blusa.cloud`; also manageable via the Dokploy MCP when connected |
| Hermes | VM on Zorak | `100.80.176.126` | Being set up, usage growing |
| Taz | **Backend/mobile developer workstation** (VM on Zorak) | `100.74.44.101` | Debian 13, 6 vCPU/16GB/232GB, user `blusa` (key auth). Node + eas-cli + clones of noctua-{backend,sensor,mobile}. Purpose: develop/build/ship without the Mac (EAS builds are cloud — no macOS needed). Disposable: rebuild rather than nurse. **T3 Code server** (see below) |
| LOLA | Debian 13, deep-learning box | `100.89.137.81` | Console fallback: GLKVM web UI at `100.94.141.50`. Node 22 via nvm (system node is 20), Claude Code installed. **T3 Code server** (see below) |

### Noctua sensors (ZeroTier)

| Name | ZT IP / ssh alias | User | Status |
|---|---|---|---|
| Riki | `10.147.18.105` / `riki.odinedge.xyz` | `blusa` | **Dado por perdido** (Pablo 2026-09-03: no encuentra el sensor físico; offline desde mayo) |
| Mama | `10.147.18.239` / `mama.odinedge.xyz` | `blusa` | No producción: se puede tocar/actualizar/restartear |
| devbox | `10.147.18.235` / `devbox.odinedge.xyz` | `dior` | Dev sensor |
| Nuno | `10.147.18.101` / `nuno.odinedge.xyz` | `blusa` | Armbian on Rockchip **RK3588** (≈devbox). RGB-IR camera variant (baby monitor). Not deployed yet. ZeroTier id `630407c070`, MAC `42:8c:c1:4d:c3:0c` |

Sensor service logs: `ssh <alias> 'journalctl -u noctua-sensor -f'` (systemd unit `noctua-sensor`).

## T3 Code (coding-agent control plane, t3.codes)

Set up 2026-09-01. Hub UI: `https://app.t3.codes` (or the desktop app) with each machine added as an environment; the browser talks to each server directly over Tailscale (HTTPS required — mixed-content blocks plain `http://100.x:3773`).

| Server | URL | How it runs |
|---|---|---|
| Taz | `https://taz.tail32621d.ts.net/` | systemd user unit `t3code.service` + linger, Tailscale Serve 443→127.0.0.1:3773 |
| LOLA | `https://lola.tail32621d.ts.net/` | same as Taz |
| Tweety | `https://tweety.tail32621d.ts.net/` | desktop app (Windows), auto-starts after reboot |

- Add a device: on the server `npx t3 pair --tailscale` → pairing URL/QR (token lasts minutes–hours; pairing is per browser/app, sessions persist after).
- Maintain (Linux): `npx t3@latest service status|update|uninstall`; logs `~/.t3/userdata/logs/boot-service.log`; `npx t3 auth` to list/revoke sessions.
- New Linux server recipe: `sudo tailscale set --operator=$USER` → Node ≥22.16 → `npx t3@latest service install` → `npx t3 pair --tailscale`. Agents (Claude Code etc.) must be installed + logged in on that machine as `blusa`.
- Tailnet MagicDNS suffix: `tail32621d.ts.net`. `blusa` is Tailscale operator on Taz and LOLA.

## Access

- Noctua sensors and Blusa.Cloud: use the ssh aliases above (defined in `~/.ssh/config`).
- Everything else: `ssh blusa@<tailscale IP>`.
- LOLA unreachable over SSH? Console via GLKVM web UI: `http://100.94.141.50`.
- Keys live in `~/.ssh` — never in this skill. No secrets here: names, IPs, users only.

## Cautions

- **Ningún sensor Noctua es de producción** (confirmado por Pablo 2026-09-03) — todos tocables. Para reiniciar `noctua-sensor` sin sudo: `kill -9 $MainPID` (un `kill` liso sale limpio y `Restart=on-failure` NO relanza; en devbox `dior` tiene sudo solo con password).
- Nothing destructive on any machine without asking first.

## Maintenance

Source of truth: `~/dotfiles-macos/claude/.claude/skills/fleet/SKILL.md` (stow package `claude`) — edit there and commit; `~/.claude/skills/fleet` is a symlink into it.

If `tailscale status` shows machines not listed here, or an entry is stale (IP/user/purpose changed, machine retired), propose updating this table and the Fleet section of `~/.claude/CLAUDE.md`.
