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

# Highlight colors for selection
HIGHLIGHT='\033[7m'  # Reverse video
NORMAL='\033[0m'

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

# Function to get state color and text
get_state_display() {
    local state=$1
    case $state in
        0) echo -e "${WHITE}[LIST]${NC}" ;;
        1) echo -e "${GREEN}[INSTALL]${NC}" ;;
        2) echo -e "${RED}[UNINSTALL]${NC}" ;;
    esac
}

# Function to draw the interface
draw_interface() {
    clear
    
    # Header
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}              Interactive Software Installer${NC}"
    echo -e "${BLUE}        Repository: bhagyajitjagdev/software-installer${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo
    echo -e "${YELLOW}Navigation:${NC} j/k or ↑↓ arrows, SPACE to cycle states, ENTER to execute, q to quit"
    echo -e "${YELLOW}States:${NC} ${WHITE}[LIST]${NC} → ${GREEN}[INSTALL]${NC} → ${RED}[UNINSTALL]${NC}"
    echo
    
    # Software list
    for i in "${!SOFTWARE_LIST[@]}"; do
        IFS=':' read -r sw_name display_name state install_func <<< "${SOFTWARE_LIST[$i]}"
        
        local state_display=$(get_state_display $state)
        
        # Check if software is already installed
        local installed_status=""
        if command_exists "$sw_name"; then
            installed_status=" ${GREEN}✓ INSTALLED${NC}"
        fi
        
        # Highlight current selection
        if [ $i -eq $CURRENT_SELECTION ]; then
            echo -e "${HIGHLIGHT} ▶ $state_display $display_name$installed_status ${NC}"
        else
            echo -e "   $state_display $display_name$installed_status"
        fi
    done
    
    echo
    echo -e "${BLUE}================================================================${NC}"
    echo -e "Use j/k keys or arrow keys to navigate, SPACE to select action, ENTER to execute"
}

# Function to read a single key
read_single_key() {
    local key
    read -rsn1 key
    
    # Handle escape sequences (arrow keys)
    if [[ $key == $'\033' ]]; then
        read -rsn2 -t 0.1 key
        case "$key" in
            '[A') echo "UP" ;;
            '[B') echo "DOWN" ;;
            *) echo "ESC" ;;
        esac
    else
        case "$key" in
            'j'|'J') echo "DOWN" ;;
            'k'|'K') echo "UP" ;;
            ' ') echo "SPACE" ;;
            $'\n'|$'\r') echo "ENTER" ;;
            'q'|'Q') echo "QUIT" ;;
            *) echo "OTHER" ;;
        esac
    fi
}

# Function to cycle software state
cycle_state() {
    local index=$1
    IFS=':' read -r sw_name display_name state install_func <<< "${SOFTWARE_LIST[$index]}"
    
    # Cycle: 0 -> 1 -> 2 -> 0
    state=$(( (state + 1) % 3 ))
    
    SOFTWARE_LIST[$index]="$sw_name:$display_name:$state:$install_func"
}

# Installation functions
install_htop() {
    print_info "Installing htop..."
    
    if command_exists htop; then
        print_warning "htop is already installed"
        return 0
    fi
    
    sudo apt-get update -qq
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
    
    sudo apt-get update -qq
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
    
    sudo apt-get update -qq
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
    
    clear
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}                    Executing Actions${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo
    
    for i in "${!SOFTWARE_LIST[@]}"; do
        IFS=':' read -r sw_name display_name state install_func <<< "${SOFTWARE_LIST[$i]}"
        
        case $state in
            1) # Install
                actions_found=true
                echo -e "${GREEN}Installing: $display_name${NC}"
                $install_func
                echo
                ;;
            2) # Uninstall
                actions_found=true
                echo -e "${RED}Uninstalling: $display_name${NC}"
                uninstall_$sw_name
                echo
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
    echo "Press any key to continue..."
    read -rsn1
}

# Main interactive loop
main_loop() {
    # Store original terminal settings
    local old_tty_settings=$(stty -g)
    
    # Set terminal to raw mode for better key handling
    stty -echo -icanon time 0 min 0
    
    while true; do
        draw_interface
        
        key=$(read_single_key)
        
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
                # Restore terminal settings before executing
                stty "$old_tty_settings"
                execute_actions
                # Set back to raw mode
                stty -echo -icanon time 0 min 0
                ;;
            "QUIT")
                break
                ;;
        esac
        
        # Small delay to prevent excessive CPU usage
        sleep 0.05
    done
    
    # Restore terminal settings
    stty "$old_tty_settings"
    clear
    print_info "Thanks for using the software installer!"
}

# Main function
main() {
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
        clear
        echo -e "${YELLOW}================================================================${NC}"
        echo -e "${YELLOW} Interactive Software Installer${NC}"
        echo -e "${YELLOW} Repository: https://github.com/bhagyajitjagdev/software-installer${NC}"
        echo -e "${YELLOW}================================================================${NC}"
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

# Handle script interruption
trap 'stty sane; clear; echo "Script interrupted."; exit 1' INT TERM

# Run main function
main "$@"
