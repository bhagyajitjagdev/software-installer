#!/bin/bash

# Interactive Software Installer v2
# https://github.com/bhagyajitjagdev/software-installer

# ── Colors ──────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'
BOLD='\033[1m'

# ── Software Registry ──────────────────────────────────
# Format for groups:   "group_name:display_name:group"
# Format for software: "group_name:software_name:display_name:software"
#
# Standard packages: just add one line here.
# Special install/uninstall logic: create install_<name>() or uninstall_<name>() override.
# Custom detection: create is_installed_<name>().

SOFTWARE_LIST=(
    "system:System Tools:group"
    "system:htop:htop - Interactive Process Viewer:software"
    "system:curl:curl - Command Line HTTP Client:software"
    "system:nmap:nmap - Network Discovery Tool:software"
    "system:tmux:tmux - Terminal Multiplexer:software"
    "system:tree:tree - Directory Tree Viewer:software"
    "system:wget:wget - Network File Downloader:software"
    "productivity:Productivity Tools:group"
    "productivity:bat:bat - Better Cat with Syntax Highlighting:software"
    "productivity:gdu:gdu - Fast disk usage analyzer:software"
    "productivity:fzf:fzf - General-purpose command-line fuzzy finder:software"
    "productivity:ripgrep:ripgrep - Fast Regex Search Tool:software"
    "productivity:fd:fd - Fast File Finder:software"
    "productivity:eza:eza - Modern ls Replacement:software"
    "productivity:zoxide:zoxide - Smarter cd Command:software"
    "productivity:jq:jq - JSON Processor:software"
    "productivity:tldr:tldr - Simplified Man Pages:software"
    "development:Development Tools:group"
    "development:docker:Docker - Container Runtime Engine:software"
    "development:fnm:fnm - Fast Node Manager:software"
    "development:uv:uv - Python Package Manager:software"
    "development:lazygit:lazygit - Terminal UI for Git:software"
    "development:gh:gh - GitHub CLI:software"
    "development:neovim:neovim - Hyperextensible Text Editor:software"
)

# ── State ───────────────────────────────────────────────
# States: 0=none, 1=install, 2=update, 3=uninstall

declare -a SOFTWARE_STATES=()
declare -a INSTALLED_CACHE=()
declare -a UPDATABLE_CACHE=()
declare -a AVAILABLE_CACHE=()
declare -a VISIBLE_MAP=()
declare -A GROUP_COLLAPSED=()
declare -A PKG_INFO_DESC=()
declare -A PKG_INFO_INST_VER=()
declare -A PKG_INFO_AVAIL_VER=()
declare -A PKG_INFO_FETCHED=()

# ── Package Manager ────────────────────────────────────
# Detected at startup. One of: apt, dnf, pacman
PM=""

# Package name overrides per PM.
# Only add entries where the name differs from the canonical name in SOFTWARE_LIST.
# Use "-" to mark a package as unavailable on that PM.
declare -A PKG_APT=( ["fd"]="fd-find" )
declare -A PKG_DNF=( ["fd"]="fd-find" ["tldr"]="-" )
declare -A PKG_PACMAN=( ["tldr"]="tealdeer" ["gh"]="github-cli" )

CURSOR_POS=0
SCROLL_OFFSET=0
SEARCH_MODE=false
SEARCH_TERM=""
INFO_VISIBLE=true

# Layout positions (calculated in calculate_layout)
TERM_LINES=0
TERM_COLS=0
HEADER_ROWS=4
CONTROLS_ROW=4
DIVIDER1_ROW=5
LIST_START=6
LIST_END=0
LIST_VISIBLE=0
DIVIDER2_ROW=0
INFO_START=0
DIVIDER3_ROW=0
STATUS_ROW=0

# ── Terminal Control ────────────────────────────────────

ESC=$'\033'
CSI="${ESC}["

TPUT_CIVIS=""
TPUT_CNORM=""
TPUT_SMCUP=""
TPUT_RMCUP=""
TPUT_EL=""

cache_tput() {
    TPUT_CIVIS=$(tput civis 2>/dev/null || printf '%s' "${CSI}?25l")
    TPUT_CNORM=$(tput cnorm 2>/dev/null || printf '%s' "${CSI}?25h")
    TPUT_SMCUP=$(tput smcup 2>/dev/null || printf '%s' "${CSI}?1049h")
    TPUT_RMCUP=$(tput rmcup 2>/dev/null || printf '%s' "${CSI}?1049l")
    TPUT_EL=$(tput el 2>/dev/null || printf '%s' "${CSI}K")
}

move_to() { printf '%s' "${CSI}${1};1H"; }
clear_line() { printf '%s%s' "${CSI}${1};1H" "$TPUT_EL"; }

# ── Helper Functions ────────────────────────────────────

print_info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
print_success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
print_warning() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
print_error() { printf "${RED}[ERR]${NC} %s\n" "$1"; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

update_bashrc() {
    local content="$1"
    local description="$2"
    if ! grep -Fxq "$content" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# $description" >> ~/.bashrc
        echo "$content" >> ~/.bashrc
        print_success "Added $description to ~/.bashrc"
    fi
}

# ── Package Manager Detection & Abstraction ─────────────

detect_pm() {
    if command_exists apt-get; then
        PM="apt"
    elif command_exists dnf; then
        PM="dnf"
    elif command_exists pacman; then
        PM="pacman"
    else
        print_error "No supported package manager found (apt, dnf, pacman). Exiting."
        exit 1
    fi
}

get_pkg_name() {
    local canonical="$1"
    local mapped=""
    case "$PM" in
        apt)    mapped="${PKG_APT[$canonical]:-}" ;;
        dnf)    mapped="${PKG_DNF[$canonical]:-}" ;;
        pacman) mapped="${PKG_PACMAN[$canonical]:-}" ;;
    esac
    if [[ -z "$mapped" ]]; then
        printf '%s' "$canonical"
    elif [[ "$mapped" == "-" ]]; then
        printf ''
    else
        printf '%s' "$mapped"
    fi
}

populate_available_cache() {
    for i in "${!SOFTWARE_LIST[@]}"; do
        parse_entry "${SOFTWARE_LIST[$i]}"
        if [[ "$_type" == "software" ]]; then
            local pkg_name
            pkg_name=$(get_pkg_name "$_software")
            if [[ -n "$pkg_name" ]]; then
                AVAILABLE_CACHE[$i]="1"
            else
                AVAILABLE_CACHE[$i]="0"
            fi
        else
            AVAILABLE_CACHE[$i]=""
        fi
    done
}

pm_install() {
    local pkg="$1"
    case "$PM" in
        apt)    sudo apt-get install -y "$pkg" ;;
        dnf)    sudo dnf install -y "$pkg" ;;
        pacman) sudo pacman -S --noconfirm "$pkg" ;;
    esac
}

pm_remove() {
    local pkg="$1"
    case "$PM" in
        apt)    sudo apt-get remove -y "$pkg" ;;
        dnf)    sudo dnf remove -y "$pkg" ;;
        pacman) sudo pacman -Rs --noconfirm "$pkg" ;;
    esac
}

pm_update() {
    case "$PM" in
        apt)    sudo apt-get update -qq ;;
        dnf)    sudo dnf check-update -q ; true ;;
        pacman) sudo pacman -Sy --noconfirm ;;
    esac
}

pm_get_upgradable() {
    case "$PM" in
        apt)    apt list --upgradable 2>/dev/null | tail -n +2 | cut -d'/' -f1 ;;
        dnf)    dnf check-update -q 2>/dev/null | awk 'NF>=3 {print $1}' | cut -d'.' -f1 ;;
        pacman) pacman -Qu 2>/dev/null | awk '{print $1}' ;;
    esac
}

pm_installed_version() {
    local pkg="$1"
    case "$PM" in
        apt)    dpkg -s "$pkg" 2>/dev/null | sed -n 's/^Version: //p' ;;
        dnf)    rpm -q --qf '%{VERSION}-%{RELEASE}' "$pkg" 2>/dev/null ;;
        pacman) pacman -Q "$pkg" 2>/dev/null | awk '{print $2}' ;;
    esac
}

pm_available_version() {
    local pkg="$1"
    case "$PM" in
        apt)    apt-cache show "$pkg" 2>/dev/null | sed -n 's/^Version: //p' | head -1 ;;
        dnf)    dnf info "$pkg" 2>/dev/null | sed -n 's/^Version[[:space:]]*: //p' | head -1 ;;
        pacman) pacman -Si "$pkg" 2>/dev/null | sed -n 's/^Version[[:space:]]*: //p' ;;
    esac
}

pm_description() {
    local pkg="$1"
    case "$PM" in
        apt)    apt-cache show "$pkg" 2>/dev/null | sed -n 's/^Description: //p' | head -1 ;;
        dnf)    dnf info "$pkg" 2>/dev/null | sed -n 's/^Summary[[:space:]]*: //p' | head -1 ;;
        pacman) pacman -Si "$pkg" 2>/dev/null | sed -n 's/^Description[[:space:]]*: //p' ;;
    esac
}

# ── Entry Parser (no subshells) ─────────────────────────
# Sets globals: _type, _group, _software, _display

parse_entry() {
    local IFS=':'
    local -a parts
    read -ra parts <<< "$1"
    local last="${parts[${#parts[@]}-1]}"
    if [[ "$last" == "group" ]]; then
        _type="group"
        _group="${parts[0]}"
        _display="${parts[1]}"
        _software=""
    else
        _type="software"
        _group="${parts[0]}"
        _software="${parts[1]}"
        _display="${parts[2]}"
    fi
}

# ── Installation Detection ──────────────────────────────

check_installed() {
    local name="$1"
    if declare -f "is_installed_$name" > /dev/null 2>&1; then
        "is_installed_$name"
    else
        command_exists "$name"
    fi
}

is_installed_bat() {
    command_exists bat || command_exists batcat
}

is_installed_ripgrep() {
    command_exists rg
}

is_installed_fd() {
    command_exists fd || command_exists fdfind
}

is_installed_neovim() {
    command_exists nvim
}

# ── Generic Install/Uninstall ──────────────────────────

generic_install() {
    local name="$1"
    local pkg_name
    pkg_name=$(get_pkg_name "$name")
    if [[ -z "$pkg_name" ]]; then
        print_error "$name is not available on this system ($PM)"
        return 1
    fi
    print_info "Installing $name..."
    if check_installed "$name"; then
        print_warning "$name is already installed"
        return 0
    fi
    if pm_install "$pkg_name"; then
        print_success "$name installed successfully"
    else
        print_error "Failed to install $name"
        return 1
    fi
}

generic_uninstall() {
    local name="$1"
    local pkg_name
    pkg_name=$(get_pkg_name "$name")
    if [[ -z "$pkg_name" ]]; then
        print_error "$name is not available on this system ($PM)"
        return 1
    fi
    print_info "Uninstalling $name..."
    if pm_remove "$pkg_name"; then
        print_success "$name uninstalled"
    else
        print_error "Failed to uninstall $name"
        return 1
    fi
}

do_install() {
    local name="$1"
    if declare -f "install_$name" > /dev/null 2>&1; then
        "install_$name"
    else
        generic_install "$name"
    fi
}

do_uninstall() {
    local name="$1"
    if declare -f "uninstall_$name" > /dev/null 2>&1; then
        "uninstall_$name"
    else
        generic_uninstall "$name"
    fi
}

# ── Special-Case Overrides ─────────────────────────────

install_bat() {
    print_info "Installing bat..."
    if check_installed bat; then
        print_warning "bat is already installed"
        # batcat alias is only needed on Debian/Ubuntu
        if [[ "$PM" == "apt" ]]; then
            update_bashrc 'alias bat="batcat --paging=never"' "Bat alias with no paging"
        fi
        return 0
    fi
    local pkg_name
    pkg_name=$(get_pkg_name "bat")
    if pm_install "$pkg_name"; then
        if [[ "$PM" == "apt" ]]; then
            update_bashrc 'alias bat="batcat --paging=never"' "Bat alias with no paging"
        fi
        print_success "bat installed successfully"
    else
        print_error "Failed to install bat"
        return 1
    fi
}

uninstall_curl() {
    print_warning "curl is a system dependency - skipping uninstall"
}

# ── Docker Overrides ──────────────────────────────────

is_installed_docker() {
    case "$PM" in
        apt)    dpkg -l docker-ce 2>/dev/null | grep -q '^ii' ;;
        dnf)    rpm -q docker-ce &>/dev/null ;;
        pacman) pacman -Q docker &>/dev/null ;;
    esac
}

install_docker() {
    print_info "Installing Docker..."
    if check_installed docker; then
        print_warning "Docker is already installed"
        return 0
    fi

    case "$PM" in
        apt)
            # Install prerequisites
            sudo apt-get install -y ca-certificates curl gnupg || { print_error "Failed to install prerequisites"; return 1; }

            # Add Docker GPG key
            sudo install -m 0755 -d /etc/apt/keyrings
            if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
                curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg
            fi

            # Add Docker repository
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            sudo apt-get update -qq
            if sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                sudo usermod -aG docker "$USER"
                print_success "Docker installed successfully"
                print_warning "Please log out and back in for Docker group membership to take effect"
            else
                print_error "Failed to install Docker"
                return 1
            fi
            ;;

        dnf)
            # Add Docker repository
            sudo dnf -y install dnf-plugins-core || { print_error "Failed to install dnf-plugins-core"; return 1; }
            sudo dnf config-manager --add-repo https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/docker-ce.repo

            if sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker "$USER"
                print_success "Docker installed successfully"
                print_warning "Please log out and back in for Docker group membership to take effect"
            else
                print_error "Failed to install Docker"
                return 1
            fi
            ;;

        pacman)
            if sudo pacman -S --noconfirm docker docker-compose docker-buildx; then
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker "$USER"
                print_success "Docker installed successfully"
                print_warning "Please log out and back in for Docker group membership to take effect"
            else
                print_error "Failed to install Docker"
                return 1
            fi
            ;;
    esac
}

uninstall_docker() {
    print_info "Uninstalling Docker..."
    if ! check_installed docker; then
        print_warning "Docker is not installed"
        return 0
    fi

    case "$PM" in
        apt)
            if sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                print_success "Docker uninstalled"
            else
                print_error "Failed to uninstall Docker"
                return 1
            fi
            ;;
        dnf)
            if sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                print_success "Docker uninstalled"
            else
                print_error "Failed to uninstall Docker"
                return 1
            fi
            ;;
        pacman)
            if sudo pacman -Rs --noconfirm docker docker-compose docker-buildx; then
                print_success "Docker uninstalled"
            else
                print_error "Failed to uninstall Docker"
                return 1
            fi
            ;;
    esac
}

# ── fnm Overrides ─────────────────────────────────────

install_fnm() {
    print_info "Installing fnm..."
    if check_installed fnm; then
        print_warning "fnm is already installed"
        return 0
    fi

    if curl -fsSL https://fnm.vercel.app/install | bash; then
        update_bashrc 'eval "$(fnm env)"' "fnm environment setup"
        print_success "fnm installed successfully"
        print_warning "Restart your shell or run: source ~/.bashrc"
    else
        print_error "Failed to install fnm"
        return 1
    fi
}

uninstall_fnm() {
    print_info "Uninstalling fnm..."
    if ! check_installed fnm; then
        print_warning "fnm is not installed"
        return 0
    fi

    rm -rf "${FNM_DIR:-$HOME/.local/share/fnm}"
    # Remove fnm from PATH in common locations
    local fnm_bin="$HOME/.local/share/fnm"
    sed -i "\|${fnm_bin}|d" ~/.bashrc 2>/dev/null || true
    sed -i '/fnm env/d' ~/.bashrc 2>/dev/null || true
    sed -i '/# fnm/d' ~/.bashrc 2>/dev/null || true
    print_success "fnm uninstalled"
}

# ── uv Overrides ──────────────────────────────────────

install_uv() {
    print_info "Installing uv..."
    if check_installed uv; then
        print_warning "uv is already installed"
        return 0
    fi

    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        print_success "uv installed successfully"
        print_warning "Restart your shell or run: source ~/.bashrc"
    else
        print_error "Failed to install uv"
        return 1
    fi
}

uninstall_uv() {
    print_info "Uninstalling uv..."
    if ! check_installed uv; then
        print_warning "uv is not installed"
        return 0
    fi

    rm -f "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx"
    rm -rf "$HOME/.local/share/uv"
    print_success "uv uninstalled"
}

# ── fd Overrides ──────────────────────────────────────

install_fd() {
    print_info "Installing fd..."
    if check_installed fd; then
        print_warning "fd is already installed"
        if [[ "$PM" == "apt" ]]; then
            update_bashrc 'alias fd="fdfind"' "fd alias for fdfind"
        fi
        return 0
    fi
    local pkg_name
    pkg_name=$(get_pkg_name "fd")
    if [[ -z "$pkg_name" ]]; then
        print_error "fd is not available on this system ($PM)"
        return 1
    fi
    if pm_install "$pkg_name"; then
        if [[ "$PM" == "apt" ]]; then
            update_bashrc 'alias fd="fdfind"' "fd alias for fdfind"
        fi
        print_success "fd installed successfully"
    else
        print_error "Failed to install fd"
        return 1
    fi
}

# ── eza Overrides ─────────────────────────────────────

install_eza() {
    print_info "Installing eza..."
    if check_installed eza; then
        print_warning "eza is already installed"
        update_bashrc 'alias ll="eza -la --git"' "eza ll alias"
        return 0
    fi
    local pkg_name
    pkg_name=$(get_pkg_name "eza")
    if [[ -z "$pkg_name" ]]; then
        print_error "eza is not available on this system ($PM)"
        return 1
    fi
    if pm_install "$pkg_name"; then
        update_bashrc 'alias ll="eza -la --git"' "eza ll alias"
        print_success "eza installed successfully"
    else
        print_error "Failed to install eza"
        return 1
    fi
}

# ── zoxide Overrides ──────────────────────────────────

install_zoxide() {
    print_info "Installing zoxide..."
    if check_installed zoxide; then
        print_warning "zoxide is already installed"
        update_bashrc 'eval "$(zoxide init bash)"' "zoxide shell integration"
        return 0
    fi
    local pkg_name
    pkg_name=$(get_pkg_name "zoxide")
    if [[ -z "$pkg_name" ]]; then
        print_error "zoxide is not available on this system ($PM)"
        return 1
    fi
    if pm_install "$pkg_name"; then
        update_bashrc 'eval "$(zoxide init bash)"' "zoxide shell integration"
        print_success "zoxide installed successfully"
        print_info "Use 'z' instead of 'cd' — it learns your habits"
    else
        print_error "Failed to install zoxide"
        return 1
    fi
}

# ── lazygit Overrides ─────────────────────────────────

install_lazygit() {
    print_info "Installing lazygit..."
    if check_installed lazygit; then
        print_warning "lazygit is already installed"
        return 0
    fi

    case "$PM" in
        pacman)
            if pm_install lazygit; then
                print_success "lazygit installed successfully"
            else
                print_error "Failed to install lazygit"
                return 1
            fi
            ;;
        *)
            local version arch
            version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            if [[ -z "$version" ]]; then
                print_error "Failed to fetch lazygit version"
                return 1
            fi
            arch=$(uname -m)
            case "$arch" in
                x86_64)  arch="x86_64" ;;
                aarch64) arch="arm64" ;;
                *)       print_error "Unsupported architecture: $arch"; return 1 ;;
            esac
            local tmpdir
            tmpdir=$(mktemp -d)
            if curl -Lo "${tmpdir}/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_${arch}.tar.gz" \
                && tar xf "${tmpdir}/lazygit.tar.gz" -C "$tmpdir" lazygit \
                && sudo install "${tmpdir}/lazygit" /usr/local/bin; then
                rm -rf "$tmpdir"
                print_success "lazygit installed successfully"
            else
                rm -rf "$tmpdir"
                print_error "Failed to install lazygit"
                return 1
            fi
            ;;
    esac
}

uninstall_lazygit() {
    print_info "Uninstalling lazygit..."
    if ! check_installed lazygit; then
        print_warning "lazygit is not installed"
        return 0
    fi

    case "$PM" in
        pacman)
            if pm_remove lazygit; then
                print_success "lazygit uninstalled"
            else
                print_error "Failed to uninstall lazygit"
                return 1
            fi
            ;;
        *)
            sudo rm -f /usr/local/bin/lazygit
            print_success "lazygit uninstalled"
            ;;
    esac
}

# ── gh (GitHub CLI) Overrides ─────────────────────────

install_gh() {
    print_info "Installing GitHub CLI..."
    if check_installed gh; then
        print_warning "GitHub CLI is already installed"
        return 0
    fi

    case "$PM" in
        apt)
            sudo mkdir -p -m 755 /etc/apt/keyrings
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
            sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
                sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update -qq
            if sudo apt-get install -y gh; then
                print_success "GitHub CLI installed successfully"
            else
                print_error "Failed to install GitHub CLI"
                return 1
            fi
            ;;
        dnf)
            sudo dnf install -y 'dnf-command(config-manager)' 2>/dev/null || true
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            if sudo dnf install -y gh; then
                print_success "GitHub CLI installed successfully"
            else
                print_error "Failed to install GitHub CLI"
                return 1
            fi
            ;;
        pacman)
            if sudo pacman -S --noconfirm github-cli; then
                print_success "GitHub CLI installed successfully"
            else
                print_error "Failed to install GitHub CLI"
                return 1
            fi
            ;;
    esac
}

# ── Data: Startup Scans ────────────────────────────────

check_updates_on_startup() {
    local upgradable=""
    upgradable=$(pm_get_upgradable) || true

    for i in "${!SOFTWARE_LIST[@]}"; do
        parse_entry "${SOFTWARE_LIST[$i]}"
        if [[ "$_type" == "software" ]]; then
            if [[ "${AVAILABLE_CACHE[$i]}" != "1" ]]; then
                INSTALLED_CACHE[$i]="0"
                UPDATABLE_CACHE[$i]="0"
                continue
            fi
            if check_installed "$_software"; then
                INSTALLED_CACHE[$i]="1"
            else
                INSTALLED_CACHE[$i]="0"
            fi
            local pkg_name
            pkg_name=$(get_pkg_name "$_software")
            if [[ "${INSTALLED_CACHE[$i]}" == "1" ]] && printf '%s\n' "$upgradable" | grep -qx "$pkg_name" 2>/dev/null; then
                UPDATABLE_CACHE[$i]="1"
            else
                UPDATABLE_CACHE[$i]="0"
            fi
        fi
    done
}

# ── Data: Package Info Cache ────────────────────────────

fetch_package_info() {
    local name="$1"
    local pkg_name desc="" inst_ver="" avail_ver=""

    pkg_name=$(get_pkg_name "$name")
    if [[ -z "$pkg_name" ]]; then
        PKG_INFO_FETCHED[$name]="1"
        PKG_INFO_DESC[$name]="Not available on $PM"
        PKG_INFO_INST_VER[$name]="N/A"
        PKG_INFO_AVAIL_VER[$name]="N/A"
        return
    fi

    inst_ver=$(pm_installed_version "$pkg_name") || true
    avail_ver=$(pm_available_version "$pkg_name") || true
    desc=$(pm_description "$pkg_name") || true

    local max_desc=$((TERM_COLS - 20))
    if (( ${#desc} > max_desc && max_desc > 3 )); then
        desc="${desc:0:$((max_desc - 3))}..."
    fi

    PKG_INFO_FETCHED[$name]="1"
    PKG_INFO_DESC[$name]="${desc:-No description available}"
    PKG_INFO_INST_VER[$name]="${inst_ver:-none}"
    PKG_INFO_AVAIL_VER[$name]="${avail_ver:-unknown}"
}

# ── Data: Filtering ─────────────────────────────────────

rebuild_visible_list() {
    VISIBLE_MAP=()
    local term_lower=""
    if [[ -n "$SEARCH_TERM" ]]; then
        term_lower=$(printf '%s' "$SEARCH_TERM" | tr '[:upper:]' '[:lower:]')
    fi

    # Pass 1: find which groups have matching software
    declare -A group_has_match=()
    local current_group_idx=-1
    for i in "${!SOFTWARE_LIST[@]}"; do
        parse_entry "${SOFTWARE_LIST[$i]}"
        if [[ "$_type" == "group" ]]; then
            current_group_idx=$i
        elif [[ "$_type" == "software" ]]; then
            if [[ -z "$term_lower" ]]; then
                group_has_match[$current_group_idx]=1
            else
                local name_lower display_lower
                name_lower=$(printf '%s' "$_software" | tr '[:upper:]' '[:lower:]')
                display_lower=$(printf '%s' "$_display" | tr '[:upper:]' '[:lower:]')
                if [[ "$name_lower" == *"$term_lower"* ]] || [[ "$display_lower" == *"$term_lower"* ]]; then
                    group_has_match[$current_group_idx]=1
                fi
            fi
        fi
    done

    # Pass 2: build visible map (respects collapsed groups)
    current_group_idx=-1
    for i in "${!SOFTWARE_LIST[@]}"; do
        parse_entry "${SOFTWARE_LIST[$i]}"
        if [[ "$_type" == "group" ]]; then
            current_group_idx=$i
            if [[ "${group_has_match[$i]}" == "1" ]]; then
                VISIBLE_MAP+=("$i")
            fi
        elif [[ "$_type" == "software" ]]; then
            # Skip items in collapsed groups
            if [[ "${GROUP_COLLAPSED[$current_group_idx]}" == "1" ]]; then
                continue
            fi
            if [[ -z "$term_lower" ]]; then
                VISIBLE_MAP+=("$i")
            else
                local name_lower display_lower
                name_lower=$(printf '%s' "$_software" | tr '[:upper:]' '[:lower:]')
                display_lower=$(printf '%s' "$_display" | tr '[:upper:]' '[:lower:]')
                if [[ "$name_lower" == *"$term_lower"* ]] || [[ "$display_lower" == *"$term_lower"* ]]; then
                    VISIBLE_MAP+=("$i")
                fi
            fi
        fi
    done
}

# ── State Cycling ───────────────────────────────────────

toggle_group() {
    if (( ${#VISIBLE_MAP[@]} == 0 )); then return; fi
    local actual_idx=${VISIBLE_MAP[$CURSOR_POS]}
    parse_entry "${SOFTWARE_LIST[$actual_idx]}"
    [[ "$_type" != "group" ]] && return

    if [[ "${GROUP_COLLAPSED[$actual_idx]}" == "1" ]]; then
        GROUP_COLLAPSED[$actual_idx]="0"
    else
        GROUP_COLLAPSED[$actual_idx]="1"
    fi
    rebuild_visible_list
    local i
    for i in "${!VISIBLE_MAP[@]}"; do
        if [[ "${VISIBLE_MAP[$i]}" == "$actual_idx" ]]; then
            CURSOR_POS=$i
            break
        fi
    done
    SCROLL_OFFSET=0
    if (( CURSOR_POS >= LIST_VISIBLE )); then
        SCROLL_OFFSET=$((CURSOR_POS - LIST_VISIBLE + 1))
    fi
    draw_list_all
    draw_status_bar
}

cycle_state() {
    if (( ${#VISIBLE_MAP[@]} == 0 )); then return; fi
    local actual_idx=${VISIBLE_MAP[$CURSOR_POS]}
    parse_entry "${SOFTWARE_LIST[$actual_idx]}"
    if [[ "$_type" == "group" ]]; then
        toggle_group
        return
    fi

    # Skip unavailable packages
    if [[ "${AVAILABLE_CACHE[$actual_idx]}" != "1" ]]; then
        return
    fi

    local current=${SOFTWARE_STATES[$actual_idx]}
    local installed="${INSTALLED_CACHE[$actual_idx]}"
    local updatable="${UPDATABLE_CACHE[$actual_idx]}"

    if [[ "$installed" == "1" ]]; then
        if [[ "$updatable" == "1" ]]; then
            case $current in
                0) SOFTWARE_STATES[$actual_idx]=2 ;;
                2) SOFTWARE_STATES[$actual_idx]=3 ;;
                *) SOFTWARE_STATES[$actual_idx]=0 ;;
            esac
        else
            case $current in
                0) SOFTWARE_STATES[$actual_idx]=3 ;;
                *) SOFTWARE_STATES[$actual_idx]=0 ;;
            esac
        fi
    else
        case $current in
            0) SOFTWARE_STATES[$actual_idx]=1 ;;
            *) SOFTWARE_STATES[$actual_idx]=0 ;;
        esac
    fi
}

# ── Layout Calculation ──────────────────────────────────

calculate_layout() {
    TERM_LINES=$(tput lines 2>/dev/null || echo 24)
    TERM_COLS=$(tput cols 2>/dev/null || echo 80)

    CONTROLS_ROW=5
    DIVIDER1_ROW=6
    LIST_START=7

    if [[ "$INFO_VISIBLE" == true ]]; then
        local info_height=3
        STATUS_ROW=$((TERM_LINES))
        DIVIDER3_ROW=$((STATUS_ROW - 1))
        INFO_START=$((DIVIDER3_ROW - info_height))
        DIVIDER2_ROW=$((INFO_START - 1))
        LIST_END=$((DIVIDER2_ROW - 1))
    else
        STATUS_ROW=$((TERM_LINES))
        DIVIDER2_ROW=$((STATUS_ROW - 1))
        LIST_END=$((DIVIDER2_ROW - 1))
        INFO_START=0
        DIVIDER3_ROW=0
    fi

    LIST_VISIBLE=$((LIST_END - LIST_START + 1))
    if (( LIST_VISIBLE < 1 )); then LIST_VISIBLE=1; fi
}

# ── Screen Init/Cleanup ────────────────────────────────

init_screen() {
    cache_tput
    printf '%s' "$TPUT_SMCUP"
    printf '%s' "$TPUT_CIVIS"
    stty -echo < /dev/tty 2>/dev/null || true
    calculate_layout
    trap cleanup_screen EXIT
    trap handle_winch WINCH 2>/dev/null || true
}

cleanup_screen() {
    printf '%s' "$TPUT_CNORM"
    printf '%s' "$TPUT_RMCUP"
    stty echo < /dev/tty 2>/dev/null || true
    printf "Thanks for using the software installer!\n"
}

handle_winch() {
    calculate_layout
    draw_full
}

# ── Drawing Functions ───────────────────────────────────

draw_header() {
    move_to 1
    printf "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    move_to 2
    local title="Interactive Software Installer v2"
    local w=62
    printf "${BLUE}║${NC}%*s%-*s${BLUE}║${NC}" $(( (w + ${#title}) / 2 )) "$title" $(( (w - ${#title} + 1) / 2 )) ""
    move_to 3
    local repo="bhagyajitjagdev/software-installer  (${PM})"
    printf "${BLUE}║${NC}%*s%-*s${BLUE}║${NC}" $(( (w + ${#repo}) / 2 )) "$repo" $(( (w - ${#repo} + 1) / 2 )) ""
    move_to 4
    printf "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
}

draw_controls() {
    clear_line $CONTROLS_ROW
    if [[ "$SEARCH_MODE" == true ]]; then
        printf "${YELLOW}Search: ${NC}%s${DIM}█${NC}  ${DIM}(Enter confirm | Esc cancel)${NC}" "$SEARCH_TERM"
    else
        printf "${YELLOW}↑↓${NC} Navigate ${DIM}|${NC} ${YELLOW}Space${NC} Select ${DIM}|${NC} ${YELLOW}/${NC} Search ${DIM}|${NC} ${YELLOW}i${NC} Info ${DIM}|${NC} ${YELLOW}R${NC} Run ${DIM}|${NC} ${YELLOW}q${NC} Quit"
    fi
}

draw_divider() {
    local row=$1
    clear_line "$row"
    printf "${BLUE}──────────────────────────────────────────────────────────────${NC}"
}

draw_row() {
    local vis_idx=$1
    if (( vis_idx < SCROLL_OFFSET || vis_idx >= SCROLL_OFFSET + LIST_VISIBLE )); then
        return
    fi

    local screen_row=$(( LIST_START + vis_idx - SCROLL_OFFSET ))
    clear_line "$screen_row"

    if (( vis_idx >= ${#VISIBLE_MAP[@]} )); then return; fi

    local actual_idx=${VISIBLE_MAP[$vis_idx]}
    parse_entry "${SOFTWARE_LIST[$actual_idx]}"

    local pointer="   "
    if (( vis_idx == CURSOR_POS )); then
        pointer=" ${YELLOW}▶${NC} "
    fi

    if [[ "$_type" == "group" ]]; then
        local arrow="▼"
        if [[ "${GROUP_COLLAPSED[$actual_idx]}" == "1" ]]; then
            arrow="▶"
        fi
        printf "%b${CYAN}${BOLD}%s %s${NC}" "$pointer" "$arrow" "$_display"
    else
        # Grey out unavailable packages
        if [[ "${AVAILABLE_CACHE[$actual_idx]}" != "1" ]]; then
            printf "%b ${DIM}[ ] %s (N/A)${NC}" "$pointer" "$_display"
            return
        fi

        local state=${SOFTWARE_STATES[$actual_idx]:-0}
        local checkbox=""
        case $state in
            0) checkbox="${DIM}[ ]${NC}" ;;
            1) checkbox="${GREEN}[+]${NC}" ;;
            2) checkbox="${YELLOW}[↑]${NC}" ;;
            3) checkbox="${RED}[-]${NC}" ;;
        esac

        local marks=""
        if [[ "${INSTALLED_CACHE[$actual_idx]}" == "1" ]]; then
            marks+=" ${GREEN}✓${NC}"
        fi
        if [[ "${UPDATABLE_CACHE[$actual_idx]}" == "1" ]]; then
            marks+=" ${YELLOW}↑${NC}"
        fi

        printf "%b %b %s%b" "$pointer" "$checkbox" "$_display" "$marks"
    fi
}

draw_list_all() {
    local start=$SCROLL_OFFSET
    local end=$((SCROLL_OFFSET + LIST_VISIBLE))
    local total=${#VISIBLE_MAP[@]}
    if (( end > total )); then end=$total; fi

    local i
    for (( i = start; i < end; i++ )); do
        draw_row "$i"
    done

    local next_row=$(( LIST_START + end - SCROLL_OFFSET ))
    local max_row=$((LIST_START + LIST_VISIBLE))
    while (( next_row <= max_row )); do
        clear_line "$next_row"
        (( next_row++ ))
    done
}

draw_info_panel() {
    if [[ "$INFO_VISIBLE" != true ]]; then return; fi
    if (( ${#VISIBLE_MAP[@]} == 0 )); then
        clear_line "$INFO_START"
        clear_line "$((INFO_START + 1))"
        clear_line "$((INFO_START + 2))"
        return
    fi

    local actual_idx=${VISIBLE_MAP[$CURSOR_POS]}
    parse_entry "${SOFTWARE_LIST[$actual_idx]}"

    if [[ "$_type" == "group" ]]; then
        clear_line "$INFO_START"
        printf " ${CYAN}${BOLD}Group:${NC} %s" "$_display"
        clear_line "$((INFO_START + 1))"
        clear_line "$((INFO_START + 2))"
        return
    fi

    if [[ "${PKG_INFO_FETCHED[$_software]}" != "1" ]]; then
        fetch_package_info "$_software"
    fi

    clear_line "$INFO_START"
    printf " ${WHITE}${BOLD}%s${NC}  %s" "$_software" "${PKG_INFO_DESC[$_software]}"

    clear_line "$((INFO_START + 1))"
    local inst_ver="${PKG_INFO_INST_VER[$_software]}"
    local avail_ver="${PKG_INFO_AVAIL_VER[$_software]}"

    if [[ "${AVAILABLE_CACHE[$actual_idx]}" != "1" ]]; then
        printf " ${DIM}Not available on %s${NC}" "$PM"
    elif [[ "${INSTALLED_CACHE[$actual_idx]}" == "1" ]]; then
        if [[ "$inst_ver" == "$avail_ver" || "${UPDATABLE_CACHE[$actual_idx]}" != "1" ]]; then
            printf " ${GREEN}Installed${NC}  ${BOLD}%s${NC}  ${GREEN}(latest)${NC}" "$inst_ver"
        else
            printf " ${YELLOW}Installed${NC}  ${BOLD}%s${NC}  →  Available: ${BOLD}%s${NC}" "$inst_ver" "$avail_ver"
        fi
    else
        printf " ${DIM}Not installed${NC}  │  Available: ${BOLD}%s${NC}" "$avail_ver"
    fi

    clear_line "$((INFO_START + 2))"
}

draw_status_bar() {
    clear_line "$STATUS_ROW"

    local install_count=0 update_count=0 uninstall_count=0
    for i in "${!SOFTWARE_STATES[@]}"; do
        case ${SOFTWARE_STATES[$i]:-0} in
            1) (( install_count++ )) || true ;;
            2) (( update_count++ )) || true ;;
            3) (( uninstall_count++ )) || true ;;
        esac
    done

    local actions=""
    (( install_count > 0 ))   && actions+="${GREEN}${install_count} install${NC} "
    (( update_count > 0 ))    && actions+="${YELLOW}${update_count} update${NC} "
    (( uninstall_count > 0 )) && actions+="${RED}${uninstall_count} remove${NC} "
    [[ -z "$actions" ]] && actions="${DIM}No actions selected${NC}"

    local filter_info=""
    if [[ -n "$SEARCH_TERM" ]]; then
        filter_info=" │ Filter: \"$SEARCH_TERM\""
    fi

    local visible=${#VISIBLE_MAP[@]}
    local total=${#SOFTWARE_LIST[@]}

    printf " %b%s │ %d/%d shown" "$actions" "$filter_info" "$visible" "$total"
}

draw_full() {
    printf '%s' "${CSI}2J"
    printf '%s' "$TPUT_CIVIS"
    draw_header
    draw_controls
    draw_divider "$DIVIDER1_ROW"
    draw_list_all
    draw_divider "$DIVIDER2_ROW"
    if [[ "$INFO_VISIBLE" == true ]]; then
        draw_info_panel
        draw_divider "$DIVIDER3_ROW"
    fi
    draw_status_bar
}

# ── Navigation ──────────────────────────────────────────

adjust_scroll() {
    local old=$SCROLL_OFFSET
    if (( CURSOR_POS < SCROLL_OFFSET )); then
        SCROLL_OFFSET=$CURSOR_POS
    elif (( CURSOR_POS >= SCROLL_OFFSET + LIST_VISIBLE )); then
        SCROLL_OFFSET=$((CURSOR_POS - LIST_VISIBLE + 1))
    fi
    [[ $old != "$SCROLL_OFFSET" ]]
}

redraw_navigation() {
    local old_cursor=$1
    if adjust_scroll; then
        draw_list_all
    else
        draw_row "$old_cursor"
        draw_row "$CURSOR_POS"
    fi
    if [[ "$INFO_VISIBLE" == true ]]; then
        draw_info_panel
    fi
}

navigate_up() {
    local total=${#VISIBLE_MAP[@]}
    (( total == 0 )) && return
    CURSOR_POS=$(( (CURSOR_POS - 1 + total) % total ))
}

navigate_down() {
    local total=${#VISIBLE_MAP[@]}
    (( total == 0 )) && return
    CURSOR_POS=$(( (CURSOR_POS + 1) % total ))
}

# ── Input Handling ──────────────────────────────────────

read_key() {
    local key
    IFS= read -rsn1 key < /dev/tty

    if [[ "$SEARCH_MODE" == true ]]; then
        case "$key" in
            "$ESC")
                local k1="" k2=""
                IFS= read -rsn1 -t 0.05 k1 < /dev/tty || true
                if [[ -z "$k1" ]]; then echo "ESC"; return; fi
                IFS= read -rsn1 -t 0.05 k2 < /dev/tty || true
                case "${k1}${k2}" in
                    '[A') echo "UP" ;;
                    '[B') echo "DOWN" ;;
                    *)    echo "OTHER" ;;
                esac
                ;;
            '')       echo "ENTER" ;;
            $'\177')  echo "BACKSPACE" ;;
            *)
                if [[ -n "$key" ]]; then
                    echo "CHAR:$key"
                else
                    echo "OTHER"
                fi
                ;;
        esac
        return
    fi

    case "$key" in
        "$ESC")
            local k1="" k2=""
            IFS= read -rsn1 -t 0.05 k1 < /dev/tty || true
            if [[ -z "$k1" ]]; then echo "ESC"; return; fi
            IFS= read -rsn1 -t 0.05 k2 < /dev/tty || true
            case "${k1}${k2}" in
                '[A') echo "UP" ;;
                '[B') echo "DOWN" ;;
                '[H') echo "HOME" ;;
                '[F') echo "END" ;;
                '[5') IFS= read -rsn1 -t 0.05 _ < /dev/tty || true; echo "PGUP" ;;
                '[6') IFS= read -rsn1 -t 0.05 _ < /dev/tty || true; echo "PGDN" ;;
                *)    echo "OTHER" ;;
            esac
            ;;
        ' ')  echo "SPACE" ;;
        '/')  echo "SEARCH" ;;
        'q'|'Q') echo "QUIT" ;;
        'r'|'R') echo "RUN" ;;
        'i'|'I') echo "INFO" ;;
        'j')  echo "DOWN" ;;
        'k')  echo "UP" ;;
        'g')  echo "HOME" ;;
        'G')  echo "END" ;;
        '')   echo "ENTER" ;;
        $'\177') echo "BACKSPACE" ;;
        *)    echo "OTHER" ;;
    esac
}

handle_normal_input() {
    local key="$1"
    local old_cursor=$CURSOR_POS
    local total=${#VISIBLE_MAP[@]}

    case "$key" in
        "UP")
            navigate_up
            redraw_navigation "$old_cursor"
            ;;
        "DOWN")
            navigate_down
            redraw_navigation "$old_cursor"
            ;;
        "HOME")
            CURSOR_POS=0
            redraw_navigation "$old_cursor"
            ;;
        "END")
            (( total > 0 )) && CURSOR_POS=$((total - 1))
            redraw_navigation "$old_cursor"
            ;;
        "PGUP")
            CURSOR_POS=$((CURSOR_POS - LIST_VISIBLE))
            (( CURSOR_POS < 0 )) && CURSOR_POS=0
            redraw_navigation "$old_cursor"
            ;;
        "PGDN")
            CURSOR_POS=$((CURSOR_POS + LIST_VISIBLE))
            local max=$(( total - 1 ))
            (( max < 0 )) && max=0
            (( CURSOR_POS > max )) && CURSOR_POS=$max
            redraw_navigation "$old_cursor"
            ;;
        "SPACE")
            cycle_state
            draw_row "$CURSOR_POS"
            draw_status_bar
            ;;
        "SEARCH")
            SEARCH_MODE=true
            SEARCH_TERM=""
            draw_controls
            ;;
        "RUN"|"ENTER")
            execute_actions
            draw_full
            ;;
        "INFO")
            if [[ "$INFO_VISIBLE" == true ]]; then
                INFO_VISIBLE=false
            else
                INFO_VISIBLE=true
            fi
            calculate_layout
            draw_full
            ;;
        "QUIT")
            return 1
            ;;
    esac
    return 0
}

handle_search_input() {
    local key="$1"

    case "$key" in
        "ENTER")
            SEARCH_MODE=false
            draw_controls
            ;;
        "ESC")
            SEARCH_MODE=false
            SEARCH_TERM=""
            rebuild_visible_list
            CURSOR_POS=0
            SCROLL_OFFSET=0
            draw_full
            ;;
        "BACKSPACE")
            if [[ -n "$SEARCH_TERM" ]]; then
                SEARCH_TERM="${SEARCH_TERM%?}"
                rebuild_visible_list
                CURSOR_POS=0
                SCROLL_OFFSET=0
                draw_controls
                draw_list_all
                draw_status_bar
                if [[ "$INFO_VISIBLE" == true ]]; then
                    draw_info_panel
                fi
            fi
            ;;
        CHAR:*)
            local ch="${key#CHAR:}"
            SEARCH_TERM+="$ch"
            rebuild_visible_list
            CURSOR_POS=0
            SCROLL_OFFSET=0
            draw_controls
            draw_list_all
            draw_status_bar
            if [[ "$INFO_VISIBLE" == true ]]; then
                draw_info_panel
            fi
            ;;
        "UP")
            local old=$CURSOR_POS
            navigate_up
            redraw_navigation "$old"
            ;;
        "DOWN")
            local old=$CURSOR_POS
            navigate_down
            redraw_navigation "$old"
            ;;
        "QUIT")
            SEARCH_MODE=false
            SEARCH_TERM=""
            rebuild_visible_list
            CURSOR_POS=0
            SCROLL_OFFSET=0
            draw_full
            ;;
    esac
}

# ── Action Execution ────────────────────────────────────

execute_actions() {
    declare -a action_types=()
    declare -a action_names=()

    for i in "${!SOFTWARE_LIST[@]}"; do
        parse_entry "${SOFTWARE_LIST[$i]}"
        [[ "$_type" == "group" ]] && continue

        case ${SOFTWARE_STATES[$i]:-0} in
            1) action_types+=("install"); action_names+=("$_software") ;;
            2) action_types+=("install"); action_names+=("$_software") ;;
            3) action_types+=("uninstall"); action_names+=("$_software") ;;
        esac
    done

    if (( ${#action_types[@]} == 0 )); then
        clear_line "$STATUS_ROW"
        printf " ${YELLOW}No actions selected! Press Space to select packages.${NC}"
        sleep 1.5
        draw_status_bar
        return
    fi

    # Exit alternate screen for package manager output
    printf '%s' "$TPUT_CNORM"
    printf '%s' "$TPUT_RMCUP"

    printf "\n${BLUE}══════════════════════════════════════════════════════════════${NC}\n"
    printf "${BLUE}                     Executing Actions${NC}\n"
    printf "${BLUE}══════════════════════════════════════════════════════════════${NC}\n\n"

    # Refresh package lists once before installs
    local has_install=false
    for t in "${action_types[@]}"; do
        [[ "$t" == "install" ]] && has_install=true && break
    done
    if [[ "$has_install" == true ]]; then
        print_info "Updating package lists..."
        pm_update || true
    fi

    local total=${#action_types[@]}
    for idx in "${!action_types[@]}"; do
        local num=$((idx + 1))
        printf "\n${CYAN}[%d/%d]${NC} " "$num" "$total"
        case "${action_types[$idx]}" in
            "install")   do_install "${action_names[$idx]}" ;;
            "uninstall") do_uninstall "${action_names[$idx]}" ;;
        esac
    done

    printf "\n"
    print_success "All actions completed! ($total packages processed)"
    printf "\n"
    read -p "Press Enter to continue..." -r < /dev/tty

    # Re-enter alternate screen
    printf '%s' "$TPUT_SMCUP"
    printf '%s' "$TPUT_CIVIS"

    # Refresh caches
    check_updates_on_startup

    # Reset states
    for i in "${!SOFTWARE_STATES[@]}"; do
        SOFTWARE_STATES[$i]=0
    done
}

# ── Main Loop ───────────────────────────────────────────

main_loop() {
    draw_full

    while true; do
        local key
        key=$(read_key)

        if [[ "$SEARCH_MODE" == true ]]; then
            handle_search_input "$key"
        else
            if ! handle_normal_input "$key"; then
                break
            fi
        fi
    done
}

# ── Entry Point ─────────────────────────────────────────

main() {
    detect_pm

    if [[ "$EUID" -eq 0 ]]; then
        print_error "Please do not run this script as root. It will ask for sudo when needed."
        exit 1
    fi

    printf "\n"
    printf "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${BLUE}║${NC}       Interactive Software Installer v2                      ${BLUE}║${NC}\n"
    printf "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}\n"
    printf "\n"
    printf "Detected package manager: ${BOLD}%s${NC}\n" "$PM"
    printf "${YELLOW}WARNING:${NC} You are about to run the software installer.\n\n"

    read -p "Do you want to continue? (y/N): " confirm < /dev/tty
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        printf "Installation cancelled.\n"
        exit 0
    fi

    # Initialize states
    for i in "${!SOFTWARE_LIST[@]}"; do
        SOFTWARE_STATES[$i]=0
    done

    printf "\nChecking installed packages and updates...\n"
    populate_available_cache
    check_updates_on_startup

    rebuild_visible_list
    init_screen
    main_loop
}

main "$@"
