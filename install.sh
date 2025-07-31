#!/bin/bash

# Interactive Software Installer with Groups
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Software groups and items
# Format: "group_name:software_name:display_name:install_function:type"
# type: software=installable software, group=group header
SOFTWARE_LIST=(
    "system:system_tools:System Tools:none:group"
    "system:htop:htop - Interactive Process Viewer:install_htop:software"
    "system:curl:curl - Command Line HTTP Client:install_curl:software"
    "system:nmap:nmap - Network Discovery Tool:install_nmap:software"
    "productivity:productivity_tools:Productivity Tools:none:group"
    "productivity:bat:bat - Better Cat with Syntax Highlighting:install_bat:software"
    "productivity:gdu:gdu - Fast disk usage analyzer:install_gdu:software"
    "productivity:fzf:fzf - General-purpose command-line fuzzy finder:install_fzf:software"
)

# Current selection and states
declare -a SOFTWARE_STATES=()
CURRENT_ROW=0
TOTAL_ITEMS=${#SOFTWARE_LIST[@]}

# Initialize states
for i in "${!SOFTWARE_LIST[@]}"; do
    SOFTWARE_STATES[$i]=0
done

# Helper functions
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
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
    print_success "curl installed successfully"
}

install_gdu() {
    print_info "Installing gdu..."
    if command_exists gdu; then
        print_warning "gdu is already installed"
        return 0
    fi
    sudo apt-get update -qq && sudo apt-get install -y gdu
    print_success "gdu installed successfully"
}

install_fzf() {
    print_info "Installing fzf..."
    if command_exists fzf; then
        print_warning "fzf is already installed"
        return 0
    fi
    sudo apt-get update -qq && sudo apt-get install -y fzf
    print_success "fzf installed successfully"
}

install_bat() {
    print_info "Installing bat..."
    if command_exists bat || command_exists batcat; then
        print_warning "bat is already installed"
        # Still add the alias if it doesn't exist
        update_bashrc 'alias bat="batcat --paging=never"' "Bat alias with no paging"
        return 0
    fi
    
    sudo apt-get update -qq && sudo apt-get install -y bat
    
    # Add bat alias for Ubuntu (where it's installed as batcat)
    update_bashrc 'alias bat="batcat --paging=never"' "Bat alias with no paging"
    
    print_success "bat installed successfully with alias"
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

uninstall_gdu() {
    print_info "Uninstalling gdu..."
    sudo apt-get remove -y gdu
    print_success "gdu uninstalled"
}

uninstall_fzf() {
    print_info "Uninstalling fzf..."
    sudo apt-get remove -y fzf
    print_success "fzf uninstalled"
}

uninstall_bat() {
    print_info "Uninstalling bat..."
    sudo apt-get remove -y bat
    print_success "bat uninstalled"
}

# Parse software entry
parse_software_entry() {
    local entry="$1"
    local field="$2"
    
    IFS=':' read -r group_name software_name display_name install_func entry_type <<< "$entry"
    
    case $field in
        "group") echo "$group_name" ;;
        "software") echo "$software_name" ;;
        "display") echo "$display_name" ;;
        "function") echo "$install_func" ;;
        "type") echo "$entry_type" ;;
    esac
}

# Draw interface
draw_interface() {
    clear
    local WIDTH=62
    local TITLE="Interactive Software Installer"
    local REPO="Repository: bhagyajitjagdev/software-installer"

    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    printf "${BLUE}║${NC}%-62s${BLUE}║${NC}\n" "$(printf "%*s" $(((${#TITLE} + WIDTH)/2)) "$TITLE")"
    printf "${BLUE}║${NC}%-62s${BLUE}║${NC}\n" "$(printf "%*s" $(((${#REPO} + WIDTH)/2)) "$REPO")"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Controls: ↑↓ Navigate | S Select/Cycle | R Run Actions | Q Quit${NC}"
    echo -e "${YELLOW}States: ${WHITE}LIST${NC} → ${GREEN}INSTALL${NC} → ${RED}UNINSTALL${NC} → ${WHITE}LIST${NC}"
    echo
    
    for i in "${!SOFTWARE_LIST[@]}"; do
        local entry="${SOFTWARE_LIST[$i]}"
        local entry_type=$(parse_software_entry "$entry" "type")
        local display_name=$(parse_software_entry "$entry" "display")
        local software_name=$(parse_software_entry "$entry" "software")
        
        if [ "$entry_type" = "group" ]; then
            # Group header
            if [ $i -eq $CURRENT_ROW ]; then
                echo -e " ${YELLOW}▶${NC} ${CYAN}${BOLD}$display_name${NC}"
            else
                echo -e "   ${CYAN}${BOLD}$display_name${NC}"
            fi
        else
            # Software item
            local state="${SOFTWARE_STATES[$i]}"
            local state_display=$(get_state_display $state)
            
            # Check if installed
            local status=""
            if command_exists "$software_name" || ([ "$software_name" = "bat" ] && command_exists "batcat"); then
                status=" ${GREEN}✓${NC}"
            fi
            
            # Highlight current row
            if [ $i -eq $CURRENT_ROW ]; then
                echo -e " ${YELLOW}▶${NC} $state_display $display_name$status"
            else
                echo -e "   $state_display $display_name$status"
            fi
        fi
    done
    
    echo
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

# Simple key reading
read_key() {
    local key
    read -rsn1 key
    
    case $key in
        $'\033')
            read -rsn2 key
            case $key in
                '[A') echo "UP" ;;
                '[B') echo "DOWN" ;;
                *) echo "OTHER" ;;
            esac
            ;;
        's'|'S') echo "SELECT" ;;
        'r'|'R') echo "RUN" ;;
        'q'|'Q') echo "QUIT" ;;
        'k'|'K') echo "UP" ;;
        'j'|'J') echo "DOWN" ;;
        *) echo "OTHER" ;;
    esac
}

# Execute actions
execute_actions() {
    local actions=()
    
    for i in "${!SOFTWARE_LIST[@]}"; do
        local entry="${SOFTWARE_LIST[$i]}"
        local entry_type=$(parse_software_entry "$entry" "type")
        
        # Skip group headers
        if [ "$entry_type" = "group" ]; then
            continue
        fi
        
        local software_name=$(parse_software_entry "$entry" "software")
        local install_func=$(parse_software_entry "$entry" "function")
        local state="${SOFTWARE_STATES[$i]}"
        
        case $state in
            1) actions+=("${install_func}") ;;
            2) actions+=("uninstall_${software_name}") ;;
        esac
    done
    
    if [ ${#actions[@]} -eq 0 ]; then
        clear
        print_warning "No actions selected!"
        echo
        read -p "Press Enter to continue..." -r
        return
    fi
    
    clear
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                     Executing Actions${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo
    
    for action in "${actions[@]}"; do
        $action
        echo
    done
    
    print_success "All actions completed!"
    
    # Reset states (only for software items, not group headers)
    for i in "${!SOFTWARE_STATES[@]}"; do
        local entry="${SOFTWARE_LIST[$i]}"
        local entry_type=$(parse_software_entry "$entry" "type")
        if [ "$entry_type" = "software" ]; then
            SOFTWARE_STATES[$i]=0
        fi
    done
    
    echo
    read -p "Press Enter to continue..." -r
}

# Main loop
main_loop() {
    local need_redraw=true
    
    while true; do
        if [ "$need_redraw" = true ]; then
            draw_interface
            need_redraw=false
        fi
        
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
            "SELECT")
                # Only allow selection on software items, not group headers
                local entry="${SOFTWARE_LIST[$CURRENT_ROW]}"
                local entry_type=$(parse_software_entry "$entry" "type")
                if [ "$entry_type" = "software" ]; then
                    SOFTWARE_STATES[$CURRENT_ROW]=$(( (SOFTWARE_STATES[$CURRENT_ROW] + 1) % 3 ))
                    need_redraw=true
                fi
                ;;
            "RUN")
                execute_actions
                need_redraw=true
                ;;
            "QUIT")
                break
                ;;
        esac
    done
    
    clear
    print_info "Thanks for using the software installer!"
}

# Main function
main() {
    if ! command_exists apt-get; then
        print_error "This script requires apt-get (Ubuntu/Debian). Exiting."
        exit 1
    fi
    
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root (sudo). It will ask for sudo when needed."
        exit 1
    fi
    
    clear
    local WIDTH=62
    local TITLE="Interactive Software Installer"
    local REPO="Repository: bhagyajitjagdev/software-installer"

    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    printf "${BLUE}║${NC}%-62s${BLUE}║${NC}\n" "$(printf "%*s" $(((${#TITLE} + WIDTH)/2)) "$TITLE")"
    printf "${BLUE}║${NC}%-62s${BLUE}║${NC}\n" "$(printf "%*s" $(((${#REPO} + WIDTH)/2)) "$REPO")"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}WARNING:${NC} You are about to run a software installer script."
    echo
    
    read -p "Do you want to continue? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled."
        exit 0
    fi
    
    main_loop
}

main "$@"