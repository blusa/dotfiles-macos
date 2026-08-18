# Global context — Pablo

## Fleet (personal machines)

| Machine | IP | SSH user | What it is |
|---|---|---|---|
| Zorak | 100.78.112.90 (TS) | blusa (or root — Unraid) | Unraid server / NAS |
| Blusa.Cloud | 100.95.237.71 (TS), alias `blusa.cloud` | blusa | Dokploy PaaS, VM on Zorak |
| Hermes | 100.80.176.126 (TS) | blusa | VM on Zorak, being set up |
| Taz | 100.74.44.101 (TS) | blusa | Backend/mobile dev workstation, VM on Zorak (Debian 13, disposable) |
| LOLA | 100.89.137.81 (TS) | blusa | Deep-learning server (Debian) |
| Riki | 10.147.18.105 (ZT), alias `riki.odinedge.xyz` | blusa | Noctua sensor — **PRODUCTION, ask before touching** |
| Mama | 10.147.18.239 (ZT), alias `mama.odinedge.xyz` | blusa | Noctua sensor — **PRODUCTION, ask before touching** |
| devbox | 10.147.18.235 (ZT), alias `devbox.odinedge.xyz` | dior | Noctua dev sensor |
| Nuno | 10.147.18.101 (ZT), alias `nuno.odinedge.xyz` | blusa | Noctua sensor variant (RK3588, RGB-IR cam), not deployed yet |
| Buster / Bugs / Silvester | — | no SSH | Laptops (macOS / Win11 / Win10-HP); Buster is usually the local machine |

Details, live discovery (`tailscale status`), cautions, and pending machines: see the **fleet** skill.
