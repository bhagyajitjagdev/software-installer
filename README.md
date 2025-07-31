# 🚀 Interactive Software Installer

An interactive terminal-based software installer for Ubuntu/Debian systems. Navigate with arrow keys, select software with visual feedback, and install multiple packages with a single command.

![Software Installer Demo](https://img.shields.io/badge/Platform-Ubuntu%2FDebian-orange)
![License](https://img.shields.io/badge/License-MIT-blue)
![Bash](https://img.shields.io/badge/Language-Bash-green)

## ✨ Features

- 🎯 **Interactive Navigation** - Use arrow keys to navigate through software options
- 🎨 **Visual Interface** - Clean, colorful terminal UI with group organization
- ⚡ **One-liner Installation** - Install with a single command
- 🔄 **State Management** - Cycle between LIST → INSTALL → UNINSTALL states
- 📦 **Grouped Software** - Organized by categories (System Tools, Productivity, etc.)
- ✅ **Installation Status** - See which software is already installed
- 🔧 **Auto Configuration** - Automatically configures aliases and settings
- 🛡️ **Safety Checks** - Won't run as root, validates system compatibility

## 🚀 Quick Start

### One-line Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bhagyajitjagdev/software-installer/main/install.sh)
```

### Alternative Methods

```bash
# Download and run locally
wget https://raw.githubusercontent.com/bhagyajitjagdev/software-installer/main/install.sh
chmod +x install.sh
./install.sh
```

## 🎮 Controls

| Key | Action |
|-----|--------|
| `↑↓` | Navigate up/down through software list |
| `j/k` | Vim-style navigation (alternative to arrows) |
| `S` | Select/Cycle state (LIST → INSTALL → UNINSTALL) |
| `R` | Run all selected actions |
| `Q` | Quit the installer |

## 📦 Available Software

### System Tools
- **htop** - Interactive process viewer
- **curl** - Command line HTTP client  
- **nmap** - Network discovery and security auditing tool

### Productivity Tools
- **bat** - A cat clone with syntax highlighting and Git integration
  - Auto-configures alias: `bat="batcat --paging=never"`

## 🎨 Interface Preview

```
╔══════════════════════════════════════════════════════════════╗
║              Interactive Software Installer                  ║
║        Repository: bhagyajitjagdev/software-installer        ║
╚══════════════════════════════════════════════════════════════╝

Controls: ↑↓ Navigate | S Select/Cycle | R Run Actions | Q Quit
States: LIST → INSTALL → UNINSTALL → LIST

   System Tools
 ▶ [ INSTALL  ] htop - Interactive Process Viewer ✓
   [ LIST     ] nmap - Network Discovery Tool
   [ UNINSTALL] curl - Command Line HTTP Client ✓
   
   Productivity Tools  
   [ INSTALL  ] bat - Better Cat with Syntax Highlighting
```

## 🔧 How It Works

1. **Navigate** through the software list using arrow keys
2. **Select software** and cycle through states:
   - `LIST` - No action (white)
   - `INSTALL` - Will install the software (green)
   - `UNINSTALL` - Will remove the software (red)
3. **Execute actions** by pressing `R` to run all selected operations
4. **Automatic configuration** - Aliases and settings are added to `~/.bashrc`

## 🛠️ Requirements

- **OS**: Ubuntu/Debian (uses `apt-get`)
- **Privileges**: Regular user account (script will request `sudo` when needed)
- **Dependencies**: `bash`, `curl`, `apt-get`

## 📋 Installation Process

The installer performs these steps:

1. **System Check** - Verifies Ubuntu/Debian compatibility
2. **Permission Check** - Ensures not running as root
3. **Interactive Selection** - User selects software to install/uninstall
4. **Package Management** - Uses `apt-get` for installations
5. **Configuration** - Adds useful aliases to `~/.bashrc`
6. **Verification** - Confirms successful installations

## 🔒 Security

- ✅ **No root execution** - Script refuses to run as root
- ✅ **Sudo when needed** - Only requests elevated privileges for package operations
- ✅ **Source verification** - Uses official package repositories
- ✅ **No permanent modifications** - Only installs requested software and adds aliases
- ✅ **Open source** - Full source code available for inspection

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Adding New Software

1. Fork the repository
2. Add your software to the `SOFTWARE_LIST` array:
   ```bash
   "group:software_name:Display Name:install_function_name:software"
   ```
3. Create the installation function:
   ```bash
   install_your_software() {
       print_info "Installing your_software..."
       if command_exists your_software; then
           print_warning "your_software is already installed"
           return 0
       fi
       sudo apt-get update -qq && sudo apt-get install -y your_software
       print_success "your_software installed successfully"
   }
   ```
4. Add uninstall function if needed
5. Submit a pull request

### Creating New Groups

Add a new group header:
```bash
"new_group:group_name:Group Display Name:none:group"
```

### Reporting Issues

- 🐛 **Bug reports** - Use GitHub Issues
- 💡 **Feature requests** - Describe your use case
- 📖 **Documentation** - Help improve this README

## 📊 Supported Distributions

| Distribution | Version | Status |
|--------------|---------|--------|
| Ubuntu | 18.04+ | ✅ Tested |
| Ubuntu | 20.04+ | ✅ Tested |
| Ubuntu | 22.04+ | ✅ Tested |
| Debian | 10+ | ✅ Should work |
| Linux Mint | 19+ | ✅ Should work |

## 🔧 Troubleshooting

### Common Issues

**Script hangs at confirmation**
```bash
# Use process substitution instead
bash <(curl -fsSL https://raw.githubusercontent.com/bhagyajitjagdev/software-installer/main/install.sh)
```

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
- Ensure you're on Ubuntu/Debian
- Run `sudo apt-get update` first
- Check if the package name is correct for your distribution

## 📝 Changelog

### v1.0.0
- ✨ Initial release
- 🎯 Interactive navigation with arrow keys
- 📦 Grouped software organization  
- 🎨 Colorful terminal interface
- ⚡ One-liner installation
- 🔧 Auto-configuration of aliases

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](#license) file for details.

## 🙏 Acknowledgments

- Inspired by modern package managers and interactive CLI tools
- Built with ❤️ for the open source community
- Thanks to all contributors and users

## 📞 Support

- 📋 **Issues**: [GitHub Issues](https://github.com/bhagyajitjagdev/software-installer/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/bhagyajitjagdev/software-installer/discussions)
- 📧 **Contact**: Open an issue for questions

---

## License

MIT License

Copyright (c) 2024 Bhagyajit Jagdev

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

<div align="center">

**⭐ Star this repo if you found it helpful!**

Made with ❤️ by [Bhagyajit Jagdev](https://github.com/bhagyajitjagdev)

</div>