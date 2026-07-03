---
name: fleet
description: Use when a task involves any of Pablo's machines — Buster, Bugs, Zorak, Blusa.Cloud, Dokploy, Hermes, LOLA, Riki, Mama, devbox, Nuno — or remote access over SSH, Tailscale, or ZeroTier (checking logs, deploying, restarting services, copying files on a remote host, Noctua sensors, *.blusa.cloud apps).
allowed-tools: Bash(ssh:*), Bash(scp:*), Bash(tailscale:*)
---

# Fleet

Pablo's personal fleet: laptops, servers, and Noctua edge sensors, reachable over Tailscale (`100.x` IPs) and/or ZeroTier (`10.147.18.x`, domain `*.odinedge.xyz`).

## Golden rule: verify before connecting

The inventory below says *what each machine is*. IPs and online state must be verified live before connecting:

- `tailscale status` — live IPs and online/offline state of Tailscale machines
- `~/.ssh/config` — existing aliases (Noctua sensors + blusa.cloud)

If live data contradicts a table below, trust the live data and offer to update this skill.

## Inventory

Default SSH user: `blusa` (exceptions noted). Last validated: 2026-07-03.

### Laptops

| Name | HW / OS | Network / IP | Purpose |
|---|---|---|---|
| Buster (`buster-bunny`) | MacBook Pro, macOS | TS `100.77.231.63` + ZT | General + mobile dev — Pablo's usual local machine |
| Bugs | ThinkPad P14s, Win 11 | TS `100.105.30.76` + ZT | Spinlock modern apps. No SSH server yet (setup pending) |
| HP EliteBook (hostname TBC) | Win 10 | TS (IP TBC) | Spinlock legacy apps. No SSH server yet |

### Servers / workstations

| Name | Role | IP (Tailscale) | Notes |
|---|---|---|---|
| Zorak | Unraid server + personal NAS | `100.78.112.90` | Exit node; hosts the Blusa.Cloud and Hermes VMs. SSH port 22 refused as of 2026-07-03 (likely disabled in Unraid settings) — use the Unraid web UI, or enable SSH first; user likely `root` (Unraid) |
| Blusa.Cloud | Dokploy PaaS (VM on Zorak) | `100.95.237.71` | Apps deployed at `*.blusa.cloud`; ssh alias `blusa.cloud`; also manageable via the Dokploy MCP when connected |
| Hermes | VM on Zorak | `100.80.176.126` | Being set up, usage growing |
| LOLA | Debian, deep-learning box | `100.89.137.81` | Console fallback: GLKVM web UI at `100.94.141.50` |

### Noctua sensors (ZeroTier)

| Name | ZT IP / ssh alias | User | Status |
|---|---|---|---|
| Riki | `10.147.18.105` / `riki.odinedge.xyz` | `blusa` | **PRODUCTION** |
| Mama | `10.147.18.239` / `mama.odinedge.xyz` | `blusa` | **PRODUCTION** |
| devbox | `10.147.18.235` / `devbox.odinedge.xyz` | `dior` | Dev sensor |
| Nuno | no IP yet | — | Not deployed; RGB-IR camera variant (baby monitor) |

Sensor service logs: `ssh <alias> 'journalctl -u noctua-sensor -f'` (systemd unit `noctua-sensor`).

## Access

- Noctua sensors and Blusa.Cloud: use the ssh aliases above (defined in `~/.ssh/config`).
- Everything else: `ssh blusa@<tailscale IP>`.
- LOLA unreachable over SSH? Console via GLKVM web UI: `http://100.94.141.50`.
- Keys live in `~/.ssh` — never in this skill. No secrets here: names, IPs, users only.

## Cautions

- **Mama and Riki are deployed production sensors**: do not reboot, restart/stop services, or edit configs without explicit confirmation from Pablo.
- Nothing destructive on any machine without asking first.

## Maintenance

Source of truth: `~/dotfiles-macos/claude/.claude/skills/fleet/SKILL.md` (stow package `claude`) — edit there and commit; `~/.claude/skills/fleet` is a symlink into it.

If `tailscale status` shows machines not listed here, or an entry is stale (IP/user/purpose changed, machine retired), propose updating this table and the Fleet section of `~/.claude/CLAUDE.md`.
