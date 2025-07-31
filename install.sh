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

# Software list with their states
declare -A SOFTWARE_STATES
SOFTWARE_NAMES=("htop" "nmap" "curl")
SOFTWARE_DESCRIPTIONS=(
    "htop - Interactive Process Viewer"
    "nmap - Network Discovery Tool"
    "curl - Command Line HTTP Client"
)

# Initialize all states to 0 (LIST)
for sw in "${SOFTWARE_NAMES[@]}"; do
    SOFTWARE_STATES[$sw]=0
done

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
    
    if ! grep -Fxq "$content" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# $description" >> ~/.bashrc
        echo "$content" >> ~/.bashrc
        print_success "Added $description to ~/.bashrc"
    else
        print_info "$description already exists in ~/.bashrc"
    fi
}

# Function to get state display
get_state_display() {
    local state=$1
    case $state in
        0) echo -e "${WHITE}[LIST]${NC}" ;;
        1) echo -e "${GREEN}[INSTALL]${NC}" ;;
        2) echo -e "${RED}[UNINSTALL]${NC}" ;;
    esac
}

# Function to cycle state
cycle_state() {
    local software=$1
    local current_state=${SOFTWARE_STATES[$software]}
    SOFTWARE_STATES[$software]=$(( (current_state + 1) % 3 ))
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
}

install_curl() {
    print_info "Installing curl..."
    
    if command_exists curl; then
        print_warning "curl is already installed"
        return 0
    fi
    
    sudo apt-get update -qq
    sudo apt-get install -y curl
    
    update_bashrc 'alias curl-json="curl -H \"Content-Type: application/json\""' "Curl JSON alias"
    
    print_success "curl installed successfully"
}

# Uninstall functions
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
    print_warning "curl is a system dependency and shouldn't be uninstalled"
    print_info "Skipping curl uninstallation for system stability"
}

# Function to show current status
show_status() {
    clear
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}              Interactive Software Installer${NC}"
    echo -e "${BLUE}        Repository: bhagyajitjagdev/software-installer${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo
    echo -e "${YELLOW}Current Selection Status:${NC}"
    echo
    
    for i in "${!SOFTWARE_NAMES[@]}"; do
        local sw="${SOFTWARE_NAMES[$i]}"
        local desc="${SOFTWARE_DESCRIPTIONS[$i]}"
        local state=${SOFTWARE_STATES[$sw]}
        local state_display=$(get_state_display $state)
        
        local installed_status=""
        if command_exists "$sw"; then
            installed_status=" ${GREEN}✓ INSTALLED${NC}"
        fi
        
        echo -e "  $(($i + 1)). $state_display $desc$installed_status"
    done
    
    echo
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${YELLOW}States:${NC} ${WHITE}[LIST]${NC} = No action, ${GREEN}[INSTALL]${NC} = Will install, ${RED}[UNINSTALL]${NC} = Will remove"
}

# Function to execute all selected actions
execute_actions() {
    local actions_found=false
    
    echo
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}                    Executing Actions${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo
    
    for sw in "${SOFTWARE_NAMES[@]}"; do
        local state=${SOFTWARE_STATES[$sw]}
        
        case $state in
            1) # Install
                actions_found=true
                install_$sw
                echo
                ;;
            2) # Uninstall
                actions_found=true
                uninstall_$sw
                echo
                ;;
        esac
    done
    
    if [ "$actions_found" = false ]; then
        print_warning "No actions selected. Nothing to do."
    else
        print_success "All actions completed!"
        
        # Reset all states to LIST
        for sw in "${SOFTWARE_NAMES[@]}"; do
            SOFTWARE_STATES[$sw]=0
        done
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Main menu function
main_menu() {
    while true; do
        show_status
        echo
        echo -e "${YELLOW}Options:${NC}"
        echo "1-3) Toggle state for software (LIST → INSTALL → UNINSTALL → LIST)"
        echo "4) Execute all selected actions"
        echo "5) Reset all to LIST state"
        echo "6) Quit"
        echo
        
        read -p "Enter your choice (1-6): " choice
        
        case $choice in
            1|2|3)
                local index=$((choice - 1))
                if [ $index -ge 0 ] && [ $index -lt ${#SOFTWARE_NAMES[@]} ]; then
                    local sw="${SOFTWARE_NAMES[$index]}"
                    cycle_state "$sw"
                    local new_state=$(get_state_display ${SOFTWARE_STATES[$sw]})
                    echo -e "\n${YELLOW}Toggled${NC} ${SOFTWARE_DESCRIPTIONS[$index]} to $new_state"
                    sleep 1
                else
                    print_error "Invalid selection"
                    sleep 1
                fi
                ;;
            4)
                execute_actions
                ;;
            5)
                for sw in "${SOFTWARE_NAMES[@]}"; do
                    SOFTWARE_STATES[$sw]=0
                done
                print_info "All states reset to LIST"
                sleep 1
                ;;
            6)
                clear
                print_info "Thanks for using the software installer!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please select 1-6."
                sleep 1
                ;;
        esac
    done
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
    
    # Show initial warning
    clear
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${YELLOW} Interactive Software Installer${NC}"
    echo -e "${YELLOW} Repository: https://github.com/bhagyajitjagdev/software-installer${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo
    echo -e "${YELLOW}WARNING:${NC} You are about to run a software installer script."
    echo -e "${YELLOW}Please review the code at the repository above.${NC}"
    echo
    
    # Only ask for confirmation if running interactively
    if [ -t 0 ]; then
        read -p "Do you want to continue? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled by user."
            exit 0
        fi
    fi
    
    # Start the main menu
    main_menu
}

# Handle interruption gracefully
trap 'clear; print_info "Script interrupted. Goodbye!"; exit 1' INT TERM

# Run main function
main "$@"
