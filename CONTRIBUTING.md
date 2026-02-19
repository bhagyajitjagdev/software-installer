# Contributing to Interactive Software Installer

Thank you for your interest in contributing to the Interactive Software Installer! 🎉

## 🚀 Quick Start

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create** a new branch for your feature
4. **Make** your changes
5. **Test** thoroughly
6. **Submit** a pull request

## 🤝 Ways to Contribute

### 🐛 Bug Reports
- Use the [GitHub Issues](https://github.com/bhagyajitjagdev/software-installer/issues) page
- Search existing issues before creating a new one
- Include your OS version, terminal type, and steps to reproduce

### 💡 Feature Requests
- Open an issue with the `enhancement` label
- Describe the use case and expected behavior
- Consider implementation complexity

### 📦 Adding New Software

Want to add software to the installer? For standard packages, it's just **one line**:

#### Standard Packages (One Line)

Add your software to the `SOFTWARE_LIST` array in `install.sh`:

```bash
"group_name:software_name:Display Name:software"
```

**Example:**
```bash
"productivity:tree:tree - Directory Tree Viewer:software"
```

That's it! The generic handler takes care of install, uninstall, and detection automatically across all supported package managers (`apt`, `dnf`, `pacman`).

#### Cross-Distro Package Names

If a package has a **different name** on different distros, add entries to the PM mapping arrays:

```bash
declare -A PKG_APT=( ["fd"]="fd-find" )   # apt installs "fd-find" for fd
declare -A PKG_DNF=()                       # dnf uses "fd" (canonical name)
declare -A PKG_PACMAN=( ["fd"]="fd" )       # pacman uses "fd"
```

Rules:
- **No entry** = use the canonical name (the `software_name` from `SOFTWARE_LIST`)
- **`"-"`** = package is unavailable on that distro (greyed out as N/A in the UI)
- **Any other string** = use that as the actual package name

**Example marking a package unavailable on apt:**
```bash
declare -A PKG_APT=( ["some_tool"]="-" )    # Not in apt repos
```

#### Special Packages (Override Functions)

If your package needs custom behavior (aliases, alternate binary names, blocked uninstall, etc.), add an override function. The script uses convention-based dispatch: if `install_<name>()` or `uninstall_<name>()` exists, it's called instead of the generic handler.

**Example with alias (PM-aware):**
```bash
install_tree() {
    print_info "Installing tree..."
    if check_installed tree; then
        print_warning "tree is already installed"
        return 0
    fi
    local pkg_name
    pkg_name=$(get_pkg_name "tree")
    if pm_install "$pkg_name"; then
        update_bashrc 'alias lt="tree -L 2"' "Tree with depth limit alias"
        print_success "tree installed successfully with alias"
    else
        print_error "Failed to install tree"
        return 1
    fi
}
```

**Example with alternate binary name:**
```bash
# If the package installs a differently-named binary
is_installed_fd() {
    command_exists fd || command_exists fdfind
}
```

**Example blocking uninstall:**
```bash
uninstall_curl() {
    print_warning "curl is a system dependency - skipping uninstall"
}
```

**Example with per-distro logic:**
```bash
install_bat() {
    # ...
    local pkg_name
    pkg_name=$(get_pkg_name "bat")
    if pm_install "$pkg_name"; then
        # batcat alias only needed on Debian/Ubuntu
        if [[ "$PM" == "apt" ]]; then
            update_bashrc 'alias bat="batcat --paging=never"' "Bat alias"
        fi
        print_success "bat installed successfully"
    fi
}
```

### 🗂️ Adding New Groups

To create a new software category:

```bash
"new_group:Group Display Name:group"
```

**Example:**
```bash
"development:Development Tools:group"
```

## 📋 Software Guidelines

### ✅ Good Software Candidates
- **Popular** and widely used
- **Available** in official repositories (apt, dnf, or pacman)
- **Useful** for developers or general users
- **Safe** and well-maintained
- **Free** and open source preferred

### ❌ Avoid These
- Proprietary software requiring licenses
- Software not in official repositories on any supported distro
- Experimental or unstable packages
- Software with complex manual setup
- Packages that require additional PPAs (unless handled via override function)

## 🧪 Testing Your Changes

Before submitting a pull request:

### 1. Test Installation
```bash
# Test your new software installation
./install.sh
# Navigate to your software and test install/uninstall
```

### 2. Test on Clean System
- Use a VM or container
- Test the one-liner command:
```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/software-installer/your-branch/install.sh | bash
```

### 3. Check All Functions
- Navigation (`↑↓` arrows, `j/k`, `PgUp/PgDn`, `g/G`)
- Selection (`Space` to cycle states)
- Search (`/` to filter, `Esc` to clear)
- Info panel (`i` to toggle)
- Execution (`R` or `Enter`)
- Smart state cycling (only valid states shown per package)

### 4. Verify Integration
- Aliases added to ~/.bashrc
- Software works after installation
- Uninstall works correctly
- No conflicts with existing software

### 5. Multi-Distro Testing
If your package has different names across distros or uses PM-specific logic:
- Test on at least one apt-based distro (Ubuntu/Debian)
- Test on dnf-based (Fedora) or pacman-based (Arch) if possible
- Verify unavailable packages show as **(N/A)** and can't be selected
- Use Docker containers for quick cross-distro testing

## 📝 Code Style

### Shell Script Guidelines
- Use **4 spaces** for indentation
- Add **comments** for complex logic
- Follow existing **naming conventions**
- Use **meaningful variable names**
- Include **error handling**

### Function Naming

Override functions follow the naming convention `install_<name>()` / `uninstall_<name>()` where `<name>` matches the `software_name` field in `SOFTWARE_LIST`. For custom detection, use `is_installed_<name>()`.

```bash
# Override: custom install (only if generic handler isn't enough)
install_software_name() {
    # Implementation
}

# Override: custom uninstall (e.g., block uninstall for system deps)
uninstall_software_name() {
    # Implementation
}

# Override: custom detection (e.g., binary has a different name)
is_installed_software_name() {
    command_exists software_name || command_exists alternate_name
}
```

### PM Abstraction Functions

Override functions should use the PM-agnostic helpers instead of calling `apt-get`/`dnf`/`pacman` directly:

| Function | Purpose |
|----------|---------|
| `pm_install(pkg)` | Install a package |
| `pm_remove(pkg)` | Remove a package |
| `pm_update()` | Update package index |
| `get_pkg_name(canonical)` | Resolve canonical name to PM-specific name |
| `check_installed(name)` | Check if a package is installed |

### Error Handling
```bash
install_example() {
    print_info "Installing example..."

    if check_installed example; then
        print_warning "example is already installed"
        return 0
    fi

    local pkg_name
    pkg_name=$(get_pkg_name "example")
    if pm_install "$pkg_name"; then
        print_success "example installed successfully"
    else
        print_error "Failed to install example"
        return 1
    fi
}
```

## 🎯 Pull Request Process

### 1. Branch Naming
- `feature/add-software-name` - For new software
- `feature/new-group-name` - For new groups
- `bugfix/description` - For bug fixes
- `docs/description` - For documentation

### 2. Commit Messages
Use clear, descriptive commit messages:
```
✨ Add tree software to productivity group
🐛 Fix arrow key navigation in some terminals  
📚 Update README with new software
🔧 Improve error handling in install functions
```

### 3. Pull Request Template
Include in your PR description:
- **What**: What software/feature you're adding
- **Why**: Why it's useful
- **Testing**: How you tested it
- **Screenshots**: If UI changes (optional)

**Example:**
```markdown
## What
Add `tree` command to the Productivity Tools group

## Why  
Tree is a useful utility for visualizing directory structure, 
commonly used by developers and system administrators.

## Testing
- ✅ Tested installation on Ubuntu 22.04
- ✅ Tested uninstallation  
- ✅ Verified alias works correctly
- ✅ Tested navigation and selection

## Notes
- Added alias `lt="tree -L 2"` for limited depth
- Includes proper error handling
```

## 🚦 Review Process

1. **Automated checks** - Code style and basic tests
2. **Manual review** - Functionality and integration
3. **Testing** - Maintainer tests on different systems
4. **Merge** - Once approved, changes are merged

## 🏷️ Issue Labels

- `bug` - Something isn't working
- `enhancement` - New feature request
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `software request` - Request for new software
- `documentation` - Improvements to docs

## 💬 Getting Help

- **Questions**: Open a [GitHub Discussion](https://github.com/bhagyajitjagdev/software-installer/discussions)
- **Issues**: Use [GitHub Issues](https://github.com/bhagyajitjagdev/software-installer/issues)
- **Ideas**: Share in discussions before implementing

## 🎉 Recognition

Contributors will be:
- Listed in the README acknowledgments
- Credited in release notes
- Given collaborator access for significant contributions

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for making the Interactive Software Installer better! 🚀