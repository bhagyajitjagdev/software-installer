<div align="center">

# Interactive Software Installer

An interactive terminal-based software installer for Linux.
Supports `apt`, `dnf`, and `pacman` — works on Ubuntu, Debian, Fedora, RHEL, Arch, Manjaro, and more.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Made_with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-informational)](https://www.linux.org/)
[![apt](https://img.shields.io/badge/apt-supported-brightgreen)](#-supported-distributions)
[![dnf](https://img.shields.io/badge/dnf-supported-brightgreen)](#-supported-distributions)
[![pacman](https://img.shields.io/badge/pacman-supported-brightgreen)](#-supported-distributions)

[![GitHub stars](https://img.shields.io/github/stars/bhagyajitjagdev/software-installer?style=social)](https://github.com/bhagyajitjagdev/software-installer/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/bhagyajitjagdev/software-installer)](https://github.com/bhagyajitjagdev/software-installer/issues)
[![GitHub last commit](https://img.shields.io/github/last-commit/bhagyajitjagdev/software-installer)](https://github.com/bhagyajitjagdev/software-installer/commits/main)

</div>

---

## Features

- **Interactive TUI** - Navigate, search, and select packages from a clean terminal interface
- **Search & Filter** - Press `/` to filter packages in real-time
- **Package Info** - View description, version, and update status for any package
- **Smart Selection** - Only shows relevant actions per package (install/update/uninstall)
- **Collapsible Groups** - Software organized by category, expand/collapse with Space
- **One-liner Install** - `curl | bash` to get started
- **Auto Configuration** - Sets up aliases and settings automatically
- **Multi-Distro** - Auto-detects `apt`, `dnf`, or `pacman`
- **Safety Checks** - Won't run as root, validates system compatibility

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/bhagyajitjagdev/software-installer/main/install.sh | bash
```

<details>
<summary><b>Alternative methods</b></summary>

```bash
# Using process substitution
bash <(curl -fsSL https://raw.githubusercontent.com/bhagyajitjagdev/software-installer/main/install.sh)

# Download and run locally
wget https://raw.githubusercontent.com/bhagyajitjagdev/software-installer/main/install.sh
chmod +x install.sh
./install.sh
```

</details>

## Interface Preview

```
╔══════════════════════════════════════════════════════════════╗
║         Interactive Software Installer v2                    ║
║         bhagyajitjagdev/software-installer  (apt)            ║
╚══════════════════════════════════════════════════════════════╝
↑↓ Navigate | Space Select | / Search | i Info | R Run | q Quit
──────────────────────────────────────────────────────────────
   ▼ System Tools
 ▶ [+] htop - Interactive Process Viewer ✓
   [ ] nmap - Network Discovery Tool
   [-] curl - Command Line HTTP Client ✓
   [ ] tmux - Terminal Multiplexer ✓

   ▶ Productivity Tools
   ▶ Development Tools
──────────────────────────────────────────────────────────────
 htop  Interactive process viewer and system monitor
 Installed  3.3.0-4  (latest)
──────────────────────────────────────────────────────────────
 2 install  1 remove │ 26/26 shown
```

## Controls

| Key | Action |
|-----|--------|
| `↑↓` / `j/k` | Navigate up/down through software list |
| `Space` | Cycle state (context-sensitive per package) |
| `/` | Enter search mode (filter packages in real-time) |
| `i` | Toggle package info panel |
| `R` / `Enter` | Execute all selected actions |
| `g` / `G` | Jump to top / bottom of list |
| `PgUp` / `PgDn` | Page navigation |
| `q` | Quit the installer |

### Selection States

States adapt to each package's current status:

| Package Status | Available States |
|---------------|-----------------|
| Not installed | `[ ]` &rarr; `[+] Install` &rarr; `[ ]` |
| Installed (up to date) | `[ ]` &rarr; `[-] Uninstall` &rarr; `[ ]` |
| Installed (update available) | `[ ]` &rarr; `[↑] Update` &rarr; `[-] Uninstall` &rarr; `[ ]` |

## Available Software

<details open>
<summary><b>System Tools</b></summary>

| Package | Description |
|---------|-------------|
| **htop** | Interactive process viewer |
| **curl** | Command line HTTP client |
| **nmap** | Network discovery and security auditing tool |
| **tmux** | Terminal multiplexer |
| **tree** | Directory tree viewer |
| **wget** | Network file downloader |

</details>

<details open>
<summary><b>Productivity Tools</b></summary>

| Package | Description | Auto-configured |
|---------|-------------|-----------------|
| **bat** | Cat clone with syntax highlighting | `bat="batcat --paging=never"` (apt) |
| **gdu** | Fast disk usage analyzer | |
| **fzf** | Command-line fuzzy finder | |
| **ripgrep** | Fast regex search tool (`rg`) | |
| **fd** | Fast file finder (alt. to `find`) | `fd="fdfind"` (apt) |
| **eza** | Modern ls replacement | `ll="eza -la --git"` |
| **zoxide** | Smarter cd that learns habits | `eval "$(zoxide init bash)"` |
| **jq** | JSON processor | |
| **tldr** | Simplified man pages | |

</details>

<details open>
<summary><b>Development Tools</b></summary>

| Package | Description | Install method |
|---------|-------------|---------------|
| **Docker** | Container runtime engine | Official repo (apt/dnf), official pkg (pacman) |
| **fnm** | Fast Node Manager | Official install script |
| **uv** | Python package manager (Astral) | Official install script |
| **lazygit** | Terminal UI for git | GitHub releases (apt/dnf), official pkg (pacman) |
| **gh** | GitHub CLI | Official repo (apt/dnf), official pkg (pacman) |
| **neovim** | Hyperextensible text editor | Package manager |

</details>

> **24 packages** across 3 categories — and adding more is just one line.

## Supported Distributions

| Package Manager | Distributions | Status |
|-----------------|--------------|--------|
| `apt` | Ubuntu 18.04+, Debian 10+, Linux Mint 19+ | Tested |
| `dnf` | Fedora 33+, RHEL 8+, Rocky Linux 8+, AlmaLinux 8+ | Supported |
| `pacman` | Arch Linux, Manjaro, EndeavourOS | Supported |

Packages that aren't available on a given distro are automatically greyed out with **(N/A)**.

## How It Works

1. **Navigate** through the software list using arrow keys or `j/k`
2. **Press Space** to cycle through context-sensitive states:
   - `[+]` Install (green) — for packages not yet installed
   - `[↑]` Update (yellow) — for installed packages with available updates
   - `[-]` Uninstall (red) — for installed packages
3. **Press `/`** to search and filter the package list
4. **Press `i`** to toggle the info panel showing package details
5. **Press `R`** to execute all selected actions as a batch
6. **Automatic configuration** - Aliases and settings are added to `~/.bashrc`

## Requirements

- **OS**: Any Linux distribution with `apt`, `dnf`, or `pacman`
- **Privileges**: Regular user account (script will request `sudo` when needed)
- **Dependencies**: `bash`, `curl`

## Security

- **No root execution** - Script refuses to run as root
- **Sudo when needed** - Only requests elevated privileges for package operations
- **Source verification** - Uses official package repositories
- **No permanent modifications** - Only installs requested software and adds aliases
- **Open source** - Full source code available for inspection

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide.

### Adding New Software

Just add **one line** to `SOFTWARE_LIST`:

```bash
"group_name:software_name:Display Name:software"
```

That's it! Install, uninstall, and detection are handled automatically across all supported package managers. For packages with special behavior, add an override function or PM mapping entry — see [CONTRIBUTING.md](CONTRIBUTING.md).

### Reporting Issues

- **Bug reports** - [Open an issue](https://github.com/bhagyajitjagdev/software-installer/issues/new)
- **Feature requests** - [Start a discussion](https://github.com/bhagyajitjagdev/software-installer/discussions)
- **Documentation** - PRs welcome

<details>
<summary><b>Troubleshooting</b></summary>

**Arrow keys not working**
- Try using `j/k` keys for navigation instead
- Ensure your terminal supports ANSI escape sequences

**Permission denied**
```bash
# Make sure you're not running as root
whoami  # Should not return 'root'

# If downloaded locally, ensure executable permissions
chmod +x install.sh
```

**Package not found**
- Run your package manager's update command first (`sudo apt-get update`, `sudo dnf check-update`, `sudo pacman -Sy`)
- Check if the package name is correct for your distribution
- Some packages may show as **(N/A)** if unavailable on your distro

**Unsupported package manager**
- The script requires `apt`, `dnf`, or `pacman`
- If you're on a different distro, contributions to add more PMs are welcome

</details>

## Changelog

### v2.1.0
- Multi-distro support: `apt`, `dnf`, `pacman`
- Package name mapping per distro
- Unavailable packages greyed out with (N/A)
- Detected package manager shown in header
- Added 18 new packages: tmux, tree, wget, ripgrep, fd, eza, zoxide, jq, tldr, Docker, fnm, uv, lazygit, gh, neovim

### v2.0.0
- Real-time search and filter
- Package info panel with description and versions
- Auto-update detection on startup
- Collapsible groups
- Smart state cycling (only relevant actions per package)
- Extended navigation: `PgUp/PgDn`, `g/G`, `Home/End`
- Batch update (runs once, not per-package)

### v1.0.0
- Initial release
- Interactive navigation with arrow keys
- Grouped software organization
- Colorful terminal interface
- One-liner installation
- Auto-configuration of aliases

## License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">

**If you found this useful, give it a** :star:

[Report Bug](https://github.com/bhagyajitjagdev/software-installer/issues/new) · [Request Feature](https://github.com/bhagyajitjagdev/software-installer/discussions) · [Contributing Guide](CONTRIBUTING.md)

Made by [Bhagyajit Jagdev](https://github.com/bhagyajitjagdev)

</div>
