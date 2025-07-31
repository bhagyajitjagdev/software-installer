#!/bin/bash

# Interactive Software Installer Script with Arrow Keys
# Repository: https://github.com/bhagyajitjagdev/software-installer
# Usage: curl -fsSL https://raw.githubusercontent.com/bhagyajitjagdev/software-installer/main/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# Software configuration
SOFTWARE_NAMES=("htop" "nmap" "curl")
SOFTWARE_DESCRIPTIONS=(
    "htop - Interactive Process Viewer"
    "nmap - Network Discovery Tool" 
    "curl - Command Line HTTP Client"
)

# State: 0=LIST(white), 1=INSTALL(green), 2=UNINSTALL(red)
declare -a SOFTWARE_STATES=(0 0 0)
CURRENT_ROW=0
TOTAL_ITEMS=${#SOFTWARE_NAMES[@]}

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if command exists
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Update ~/.bashrc
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

# Get state display
get_state_display() {
    case $1 in
        0) echo -e "${WHITE}[ LIST     ]${NC}" ;;
        1) echo -e "${GREEN}[ INSTALL  ]${NC}" ;;
        2) echo -e "${RED}[ UNINSTALL]${NC}" ;;
    esac
}

# Installation functions
install_htop() {
    print_info "Installing htop..."
    if command_exists htop; then
        print_warning "htop is already installed"
        return 0
    fi
    sudo apt-get update -qq && sudo apt-get install -y htop
    print_success "htop installed successfully"
}

install_nmap() {
    print_info "Installing nmap..."
    if command_exists nmap; then
        print_warning "nmap is already installed"
        return 0
    fi
    sudo apt-get update -qq && sudo apt-get install -y nmap
    print_success "nmap installed successfully"
}

install_curl() {
    print_info "Installing curl..."
    if command_exists curl; then
        print_warning "curl is already installed"
        return 0
    fi
    sudo apt-get update -qq && sudo apt-get install -y curl
    update_bashrc 'alias curl-json="curl -H \"Content-Type: application/json\""' "Curl JSON alias"
    print_success "curl installed successfully"
}

# Uninstall functions
uninstall_htop() {
    print_info "Uninstalling htop..."
    sudo apt-get remove -y htop
    print_success "htop uninstalled"
}

uninstall_nmap() {
    print_info "Uninstalling nmap..."
    sudo apt-get remove -y nmap
    print_success "nmap uninstalled"
}

uninstall_curl() {
    print_warning "curl is a system dependency - skipping uninstall"
}

# Draw the interface
draw_interface() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}              ${BOLD}Interactive Software Installer${NC}              ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}        Repository: bhagyajitjagdev/software-installer        ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Controls: ↑↓ Navigate | SPACE Cycle State | ENTER Execute | Q Quit${NC}"
    echo -e "${YELLOW}States: ${WHITE}LIST${NC} → ${GREEN}INSTALL${NC} → ${RED}UNINSTALL${NC} → ${WHITE}LIST${NC}${NC}"
    echo
    
    # Draw software list
    for i in "${!SOFTWARE_NAMES[@]}"; do
        local sw="${SOFTWARE_NAMES[$i]}"
        local desc="${SOFTWARE_DESCRIPTIONS[$i]}"
        local state="${SOFTWARE_STATES[$i]}"
        local state_display=$(get_state_display $state)
        
        # Check if installed
        local status=""
        if command_exists "$sw"; then
            status=" ${GREEN}✓${NC}"
        fi
        
        # Highlight current row
        if [ $i -eq $CURRENT_ROW ]; then
            echo -e " ${YELLOW}▶${NC} $state_display $desc$status"
        else
            echo -e "   $state_display $desc$status"
        fi
    done
    
    echo
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

# Read a single key with proper escape sequence handling
read_key() {
    local key
    local key2
    local key3
    
    # Read first character
    read -rsn1 key
    
    # Check if it's an escape sequence
    if [[ $key == $'\033' ]]; then
        # Read the next character
        read -rsn1 -t 0.001 key2
        if [[ $key2 == '[' ]]; then
            # Read the final character
            read -rsn1 -t 0.001 key3
            case $key3 in
                'A') echo "UP" ;;
                'B') echo "DOWN" ;;
                *) echo "OTHER" ;;
            esac
        else
            echo "ESC"
        fi
    else
        case $key in
            ' ') echo "SPACE" ;;
            $'\n'|$'\r') echo "ENTER" ;;
            'q'|'Q') echo "QUIT" ;;
            'k'|'K') echo "UP" ;;
            'j'|'J') echo "DOWN" ;;
            *) echo "OTHER" ;;
        esac
    fi
}

# Execute selected actions
execute_actions() {
    local actions=()
    
    # Collect actions
    for i in "${!SOFTWARE_NAMES[@]}"; do
        local sw="${SOFTWARE_NAMES[$i]}"
        local state="${SOFTWARE_STATES[$i]}"
        
        case $state in
            1) actions+=("install_$sw:Installing $sw") ;;
            2) actions+=("uninstall_$sw:Uninstalling $sw") ;;
        esac
    done
    
    if [ ${#actions[@]} -eq 0 ]; then
        clear
        print_warning "No actions selected!"
        echo
        read -p "Press Enter to continue..." -r
        return
    fi
    
    # Execute actions
    clear
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                     Executing Actions${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo
    
    for action in "${actions[@]}"; do
        IFS=':' read -r func desc <<< "$action"
        echo -e "${YELLOW}$desc...${NC}"
        $func
        echo
    done
    
    print_success "All actions completed!"
    
    # Reset states
    for i in "${!SOFTWARE_STATES[@]}"; do
        SOFTWARE_STATES[$i]=0
    done
    
    echo
    read -p "Press Enter to continue..." -r
}

# Main interactive loop - ONLY redraw when needed
main_loop() {
    local need_redraw=true
    
    while true; do
        # Only redraw if needed
        if [ "$need_redraw" = true ]; then
            draw_interface
            need_redraw=false
        fi
        
        # Read key (this blocks until key is pressed)
        local key=$(read_key)
        
        case $key in
            "UP")
                CURRENT_ROW=$(( (CURRENT_ROW - 1 + TOTAL_ITEMS) % TOTAL_ITEMS ))
                need_redraw=true
                ;;
            "DOWN") 
                CURRENT_ROW=$(( (CURRENT_ROW + 1) % TOTAL_ITEMS ))
                need_redraw=true
                ;;
            "SPACE")
                SOFTWARE_STATES[$CURRENT_ROW]=$(( (SOFTWARE_STATES[$CURRENT_ROW] + 1) % 3 ))
                need_redraw=true
                ;;
            "ENTER")
                execute_actions
                need_redraw=true
                ;;
            "QUIT")
                break
                ;;
            *)
                # Do nothing for other keys, don't redraw
                ;;
        esac
    done
    
    clear
    print_info "Thanks for using the software installer!"
}

# Get input that works with pipes
get_input() {
    local prompt="$1"
    local response
    
    if [ ! -t 0 ]; then
        exec < /dev/tty
    fi
    
    read -p "$prompt" -r response
    echo "$response"
}

# Main function
main() {
    # System checks
    if ! command_exists apt-get; then
        print_error "This script requires apt-get (Ubuntu/Debian). Exiting."
        exit 1
    fi
    
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root (sudo). It will ask for sudo when needed."
        exit 1
    fi
    
    # Initial confirmation
    clear
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC} ${BOLD}Interactive Software Installer${NC}                              ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC} Repository: https://github.com/bhagyajitjagdev/software-installer ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}WARNING:${NC} You are about to run a software installer script."
    echo
    
    local confirm=$(get_input "Do you want to continue? (y/N): ")
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled."
        exit 0
    fi
    
    # Start interactive interface
    main_loop
}

# Run the script
main "$@"
