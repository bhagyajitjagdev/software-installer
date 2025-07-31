#!/bin/bash

# Interactive Software Installer Script
# Repository: https://github.com/bhagyajitjagdev/software-installer
# Usage: curl -fsSL https://raw.githubusercontent.com/bhagyajitjagdev/software-installer/main/install.sh | bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Background colors for selection
BG_WHITE='\033[47m\033[30m'
BG_GREEN='\033[42m\033[30m'
BG_RED='\033[41m\033[37m'

# Software list with their states
# Format: "software_name:display_name:current_state:install_function"
SOFTWARE_LIST=(
    "htop:htop - Interactive Process Viewer:0:install_htop"
    "nmap:nmap - Network Discovery Tool:0:install_nmap"
    "curl:curl - Command Line HTTP Client:0:install_curl"
)

# State meanings: 0=white/list, 1=green/install, 2=red/uninstall
CURRENT_SELECTION=0
TOTAL_SOFTWARE=${#SOFTWARE_LIST[@]}

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to update ~/.bashrc
update_bashrc() {
    local content="$1"
    local description="$2"
    
    # Check if the content already exists in ~/.bashrc
    if ! grep -Fxq "$content" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# $description" >> ~/.bashrc
        echo "$content" >> ~/.bashrc
        print_success "Added $description to ~/.bashrc"
    else
        print_info "$description already exists in ~/.bashrc"
    fi
}

# Function to hide cursor
hide_cursor() {
    printf '\033[?25l'
}

# Function to show cursor
show_cursor() {
    printf '\033[?25h'
}

# Function to move cursor to position
move_cursor() {
    printf '\033[%d;%dH' "$1" "$2"
}

# Function to clear screen
clear_screen() {
    printf '\033[2J\033[H'
}

# Function to get software state color
get_state_color() {
    local state=$1
    case $state in
        0) echo -e "${BG_WHITE}" ;;      # White background for list
        1) echo -e "${BG_GREEN}" ;;      # Green background for install
        2) echo -e "${BG_RED}" ;;        # Red background for uninstall
    esac
}

# Function to get state text
get_state_text() {
    local state=$1
    case $state in
        0) echo "LIST" ;;
        1) echo "INSTALL" ;;
        2) echo "UNINSTALL" ;;
    esac
}

# Function to draw the interface
draw_interface() {
    clear_screen
    
    # Header
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}              ${BOLD}Interactive Software Installer${NC}              ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}        Repository: bhagyajitjagdev/software-installer        ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Navigation:${NC} ↑↓ arrows to move, SPACE to cycle states, ENTER to execute, Q to quit"
    echo -e "${YELLOW}States:${NC} ${BG_WHITE} LIST ${NC} → ${BG_GREEN} INSTALL ${NC} → ${BG_RED} UNINSTALL ${NC} → ${BG_WHITE} LIST ${NC}"
    echo
    
    # Software list
    for i in "${!SOFTWARE_LIST[@]}"; do
        IFS=':' read -r sw_name display_name state install_func <<< "${SOFTWARE_LIST[$i]}"
        
        local prefix="  "
        local suffix=""
        
        # Highlight current selection
        if [ $i -eq $CURRENT_SELECTION ]; then
            prefix="▶ "
            suffix=" ◀"
        fi
        
        # Get state color and text
        local state_color=$(get_state_color $state)
        local state_text=$(get_state_text $state)
        
        # Check if software is already installed
        local installed_status=""
        if command_exists "$sw_name"; then
            installed_status=" ${GREEN}[INSTALLED]${NC}"
        fi
        
        echo -e "${prefix}${state_color} ${state_text} ${NC} ${display_name}${installed_status}${suffix}"
    done
    
    echo
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

# Function to cycle software state
cycle_state() {
    local index=$1
    IFS=':' read -r sw_name display_name state install_func <<< "${SOFTWARE_LIST[$index]}"
    
    # Cycle: 0 -> 1 -> 2 -> 0
    state=$(( (state + 1) % 3 ))
    
    SOFTWARE_LIST[$index]="$sw_name:$display_name:$state:$install_func"
}

# Function to handle key input
read_key() {
    local key
    read -rsn1 key
    
    case "$key" in
        $'\033')  # ESC sequence
            read -rsn2 key
            case "$key" in
                '[A') echo "UP" ;;      # Up arrow
                '[B') echo "DOWN" ;;    # Down arrow
            esac
            ;;
        ' ') echo "SPACE" ;;            # Space bar
        $'\n') echo "ENTER" ;;          # Enter key
        'q'|'Q') echo "QUIT" ;;         # Q key
        *) echo "OTHER" ;;
    esac
}

# Installation functions
install_htop() {
    print_info "Installing htop..."
    
    if command_exists htop; then
        print_warning "htop is already installed"
        return 0
    fi
    
    sudo apt-get update
    sudo apt-get install -y htop
    
    print_success "htop installed successfully"
    return 0
}

install_nmap() {
    print_info "Installing nmap..."
    
    if command_exists nmap; then
        print_warning "nmap is already installed"
        return 0
    fi
    
    sudo apt-get update
    sudo apt-get install -y nmap
    
    print_success "nmap installed successfully"
    return 0
}

install_curl() {
    print_info "Installing curl..."
    
    if command_exists curl; then
        print_warning "curl is already installed"
        return 0
    fi
    
    sudo apt-get update
    sudo apt-get install -y curl
    
    # Add useful curl aliases
    update_bashrc 'alias curl-json="curl -H \"Content-Type: application/json\""' "Curl JSON alias"
    
    print_success "curl installed successfully"
    return 0
}

# Uninstallation functions
uninstall_htop() {
    print_info "Uninstalling htop..."
    sudo apt-get remove -y htop
    print_success "htop uninstalled successfully"
}

uninstall_nmap() {
    print_info "Uninstalling nmap..."
    sudo apt-get remove -y nmap
    print_success "nmap uninstalled successfully"
}

uninstall_curl() {
    print_info "Uninstalling curl..."
    print_warning "curl is a system dependency and shouldn't be uninstalled"
    print_info "Skipping curl uninstallation for system stability"
}

# Function to execute actions
execute_actions() {
    local actions_found=false
    
    for i in "${!SOFTWARE_LIST[@]}"; do
        IFS=':' read -r sw_name display_name state install_func <<< "${SOFTWARE_LIST[$i]}"
        
        case $state in
            1) # Install
                actions_found=true
                $install_func
                ;;
            2) # Uninstall
                actions_found=true
                uninstall_$sw_name
                ;;
        esac
    done
    
    if [ "$actions_found" = false ]; then
        print_warning "No actions selected. Nothing to do."
    else
        print_success "All actions completed!"
        
        # Reset all states to 0 (list)
        for i in "${!SOFTWARE_LIST[@]}"; do
            IFS=':' read -r sw_name display_name state install_func <<< "${SOFTWARE_LIST[$i]}"
            SOFTWARE_LIST[$i]="$sw_name:$display_name:0:$install_func"
        done
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Main interactive loop
main_loop() {
    hide_cursor
    
    while true; do
        draw_interface
        
        key=$(read_key)
        
        case "$key" in
            "UP")
                CURRENT_SELECTION=$(( (CURRENT_SELECTION - 1 + TOTAL_SOFTWARE) % TOTAL_SOFTWARE ))
                ;;
            "DOWN")
                CURRENT_SELECTION=$(( (CURRENT_SELECTION + 1) % TOTAL_SOFTWARE ))
                ;;
            "SPACE")
                cycle_state $CURRENT_SELECTION
                ;;
            "ENTER")
                show_cursor
                clear_screen
                execute_actions
                hide_cursor
                ;;
            "QUIT")
                break
                ;;
        esac
    done
    
    show_cursor
    clear_screen
    print_info "Thanks for using the software installer!"
}

# Cleanup function
cleanup() {
    show_cursor
    clear_screen
}

# Main function
main() {
    # Set trap for cleanup
    trap cleanup EXIT INT TERM
    
    # Check if running on Ubuntu/Debian
    if ! command_exists apt-get; then
        print_error "This script requires apt-get (Ubuntu/Debian). Exiting."
        exit 1
    fi
    
    # Make sure script is not run as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root (sudo). It will ask for sudo when needed."
        exit 1
    fi
    
    # Show initial warning when run via curl
    if [ -t 0 ]; then
        echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║${NC} ${BOLD}Interactive Software Installer${NC}                              ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC} Repository: https://github.com/bhagyajitjagdev/software-installer ${YELLOW}║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo
        echo -e "${YELLOW}WARNING:${NC} You are about to run a software installer script."
        echo -e "${YELLOW}Please review the code at the repository above.${NC}"
        echo
        read -p "Do you want to continue? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled by user."
            exit 0
        fi
        echo
    fi
    
    # Start the interactive interface
    main_loop
}

# Run main function
main "$@"
