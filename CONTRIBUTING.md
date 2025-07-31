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

Want to add software to the installer? Here's how:

#### Step 1: Add to Software List
Add your software to the `SOFTWARE_LIST` array in `install.sh`:

```bash
"group_name:software_name:Display Name:install_function_name:software"
```

**Example:**
```bash
"productivity:tree:tree - Directory Tree Viewer:install_tree:software"
```

#### Step 2: Create Installation Function
```bash
install_tree() {
    print_info "Installing tree..."
    if command_exists tree; then
        print_warning "tree is already installed"
        return 0
    fi
    sudo apt-get update -qq && sudo apt-get install -y tree
    print_success "tree installed successfully"
}
```

#### Step 3: Create Uninstall Function
```bash
uninstall_tree() {
    print_info "Uninstalling tree..."
    sudo apt-get remove -y tree
    print_success "tree uninstalled"
}
```

#### Step 4: Add Configuration (Optional)
If your software needs aliases or configuration:
```bash
install_tree() {
    # ... installation code ...
    
    # Add useful alias
    update_bashrc 'alias lt="tree -L 2"' "Tree with depth limit alias"
    
    print_success "tree installed successfully with alias"
}
```

### 🗂️ Adding New Groups

To create a new software category:

```bash
"new_group:group_identifier:Group Display Name:none:group"
```

**Example:**
```bash
"development:dev_tools:Development Tools:none:group"
```

## 📋 Software Guidelines

### ✅ Good Software Candidates
- **Popular** and widely used
- **Available** in Ubuntu/Debian repositories
- **Useful** for developers or general users
- **Safe** and well-maintained
- **Free** and open source preferred

### ❌ Avoid These
- Proprietary software requiring licenses
- Software not in official repositories
- Experimental or unstable packages
- Software with complex manual setup
- Packages that require additional PPAs

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
bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/software-installer/your-branch/install.sh)
```

### 3. Check All Functions
- Navigation (↑↓ arrows)
- Selection (S key)
- Execution (R key)
- State changes (LIST → INSTALL → UNINSTALL)

### 4. Verify Integration
- Aliases added to ~/.bashrc
- Software works after installation
- Uninstall works correctly
- No conflicts with existing software

## 📝 Code Style

### Shell Script Guidelines
- Use **4 spaces** for indentation
- Add **comments** for complex logic
- Follow existing **naming conventions**
- Use **meaningful variable names**
- Include **error handling**

### Function Naming
```bash
# Installation functions
install_software_name() {
    # Implementation
}

# Uninstall functions  
uninstall_software_name() {
    # Implementation
}
```

### Error Handling
```bash
install_example() {
    print_info "Installing example..."
    
    if command_exists example; then
        print_warning "example is already installed"
        return 0
    fi
    
    if sudo apt-get update -qq && sudo apt-get install -y example; then
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