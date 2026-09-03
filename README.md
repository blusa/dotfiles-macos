# dotfiles

Dotfiles de Pablo, manejados con [GNU Stow](https://www.gnu.org/software/stow/).
Cada directorio es un "paquete" que replica la estructura desde `$HOME`.

## Setup en una máquina nueva

```sh
git clone https://github.com/blusa/dotfiles-macos.git ~/dotfiles-macos
cd ~/dotfiles-macos
brew bundle              # instala todo el Brewfile (taps de terceros requieren brew trust)

# Evitar que stow "pliegue" dirs enteros al repo (linkearía ~/.claude completo,
# y el estado local de Claude Code terminaría escribiéndose dentro del repo):
mkdir -p ~/.claude/skills ~/.claude/hooks ~/.config ~/.agents

stow $(command ls -d */ | grep -vx 't3/')   # symlinkea todos los paquetes (menos t3, ver abajo)

# T3 Code rechaza symlinks en su dir de themes (O_NOFOLLOW), va por copia:
cp t3/.t3/userdata/themes/*.json ~/.t3/userdata/themes/
```

Para traer solo Claude Code (CLAUDE.md global + skills propias como `fleet`) a
una máquina, alcanza con el `mkdir` de arriba y `stow claude` (+ `stow agents`
y `npx skills install` si querés las skills de terceros).

## Paquetes

| Paquete | Qué versiona |
|---|---|
| `zsh`, `starship`, `tmux`, `tmuxinator`, `wezterm` | Shell y terminal (tema tokyonight OLED) |
| `git` | `.gitconfig` + `.gitignore_global` |
| `nvim` | Config LazyVim |
| `aerospace`, `borders`, `autoraise` | Tiling WM + borde de foco + focus-follows-mouse (macOS only) |
| `raycast` | Symlink de `~/.config/raycast` (las `extensions/` están gitignoreadas: Raycast las auto-actualiza) |
| `claude` | Claude Code: `CLAUDE.md` global, `settings.json` (hooks herdr, statusline), `hooks/`, y skills propias (`fleet`, `noctua-app-release`) |
| `agents` | `.skill-lock.json` de las skills de terceros (ver abajo) |
| `t3` | Theme "Tokyo Night OLED" para T3 Code — **se copia, no se stowea** |
| `ssh` | `~/.ssh/config` (solo hosts, sin claves) |

## Skills de Claude Code

- **Propias** (`claude/.claude/skills/`): versionadas acá, symlinkeadas a `~/.claude/skills/`.
- **De terceros** (`~/.agents/skills/`): instaladas con [vercel-labs/skills](https://github.com/vercel-labs/skills)
  (`npx skills add <owner/repo>`); no se vendorean, se reinstalan desde el lockfile:
  `npx skills install` lee `~/.agents/.skill-lock.json` (versionado en `agents/`).

## Servicios (brew services)

`borders` y `autoraise` corren como servicios de brew y arrancan al login.
AutoRaise necesita permiso de Accesibilidad (System Settings → Privacy & Security)
apuntando a `/opt/homebrew/opt/autoraise/bin/AutoRaise`.

## Pendiente

- Migración a Linux: `aerospace`/`borders`/`autoraise`/`raycast` no aplican;
  el resto es portable (ojo: `claude/settings.json` tiene paths absolutos `/Users/blusa/...`).
