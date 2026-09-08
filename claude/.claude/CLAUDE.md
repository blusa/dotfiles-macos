# Global context — Pablo

## Fleet (personal machines)

| Machine | IP | SSH user | What it is |
|---|---|---|---|
| Zorak | 100.78.112.90 (TS) | blusa (or root — Unraid) | Unraid server / NAS |
| Blusa.Cloud | 100.95.237.71 (TS), alias `blusa.cloud` | blusa | Dokploy PaaS, VM on Zorak |
| Hermes | 100.80.176.126 (TS) | blusa | VM on Zorak, being set up |
| Taz | 100.74.44.101 (TS) | blusa | Backend/mobile dev workstation, VM on Zorak (Debian 13, disposable). T3 Code server. POR DECOMISIONAR — nada debe vivir solo ahí |
| LOLA | 100.89.137.81 (TS) | blusa | Deep-learning server (Debian 13). T3 Code server |
| Tweety | 100.112.179.45 (TS) | no SSH | Windows PC — offline, evitar usar (se retira a favor de Bugs) |
| Marvin | 100.77.55.34 (TS) | no SSH | Windows PC, purpose TBC |
| Riki | 10.147.18.105 (ZT), alias `riki.odinedge.xyz` | blusa | Noctua sensor — dado por perdido (2026-09-03) |
| Mama | 10.147.18.239 (ZT), alias `mama.odinedge.xyz` | blusa | Noctua sensor — no producción, tocable |
| devbox | 10.147.18.235 (ZT), alias `devbox.odinedge.xyz` | dior | Noctua dev sensor |
| Nuno | 10.147.18.101 (ZT), alias `nuno.odinedge.xyz` | blusa | Noctua sensor variant (RK3588, RGB-IR cam), not deployed yet |
| Buster / Bugs / Silvester | — | no SSH | Laptops. Buster: MacBook, usually local machine y futuro fleet-control. Bugs: Win11, main Windows dev. Silvester: go-to terminal laptop (hoy HP Win10; plan: X1 Carbon con Omarchy) |

Details, live discovery (`tailscale status`), cautions, and pending machines: see the **fleet** skill.
