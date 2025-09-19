# Windows Reset Toolkit 2.0

> Professional PowerShell-based Windows administration and troubleshooting suite with Active Directory integration.

## 🎯 Overview

**ReSet Toolkit 2.0** is an enterprise-grade PowerShell toolkit designed for comprehensive Windows system reset, troubleshooting, and maintenance. This professional-grade solution provides 75+ specialized functions across 29 modules, featuring advanced Active Directory integration, comprehensive backup systems, and standalone admin tools.

**🔥 NEW IN 2.0: Active Directory Integration, Advanced Backup System, Performance Optimization, and Professional Admin Tools!**

## 📊 Enhanced Function Summary

| Category | Modules | Functions | Key Features |
|----------|---------|-----------|--------------|
| **Core Utilities** | 1 | 26 | Logging, backup/restore, system health, AD connectivity |
| **Active Directory** | 2 | 15 | Domain management, host cleanup, trust repair |
| **Performance** | 1 | 8 | Memory optimization, disk tuning, service profiles |
| **Windows Components** | 25 | 50+ | Complete Windows settings reset coverage |
| **Admin Tools** | 3 | - | Health check, AD tools, system cleanup |
| **Total** | **32** | **99+** | **Enterprise-ready administration suite** |

## 🚀 Key Features

### **🆕 New in Version 2.0**
- **🌐 Active Directory Integration**: Comprehensive domain management and troubleshooting
- **💾 Advanced Backup System**: Compressed backups with verification and restore
- **⚡ Performance Optimization**: System tuning with multiple performance profiles
- **🛠️ Standalone Admin Tools**: Independent utilities for quick diagnostics
- **📊 System Health Monitoring**: Real-time health assessment and reporting
- **🔧 Host Computer Cleanup**: Specialized AD cleanup for domain-joined machines

### **🎯 Core Features**
- **🎯 Comprehensive Coverage**: 99+ functions across all Windows components
- **🛡️ Enterprise Security**: Backup-first operations with full rollback support
- **📊 Professional Logging**: Comprehensive audit trails and operation tracking
- **🎨 Interactive CLI**: Rich PowerShell interface with menu system
- **⚡ Batch Processing**: Automated workflows and scripting support
- **🔒 Administrator Enforcement**: Mandatory elevation for system safety
- **💻 Modern Compatibility**: Windows 10/11 with PowerShell 5.0+

## 🛠️ Enhanced Tools & Modules

### **🎛️ Main Interface**
- **`Reset-Manager.ps1`** - Interactive CLI with comprehensive menu system

### **🏥 Standalone Admin Tools**
- **`HealthCheck.ps1`** - Quick system health assessment with HTML reports
- **`AD-Tools.ps1`** - Interactive Active Directory troubleshooting toolkit
- **`SystemCleanup.ps1`** - Advanced system cleanup with selective options

### **⚙️ Installation & Setup**
- **`Install.ps1`** - Enhanced installer with dependency management and shortcuts

## 🌐 Active Directory Features

### **Domain Management** (`reset-active-directory.ps1`)
- **Domain Connectivity Reset** - Repair domain connection and trust relationships
- **AD Credentials Management** - Clear cached credentials and Kerberos tickets
- **Group Policy Cache Reset** - Clear GP cache and force refresh
- **Kerberos Authentication Reset** - Reset Kerberos settings and tickets
- **AD DNS Configuration** - Reset DNS settings for domain connectivity
- **AD Services Management** - Restart and optimize AD-related services
- **AD Client Cache Cleanup** - Clear client-side Active Directory cache

### **Host Computer Cleanup** (`reset-ad-host-cleanup.ps1`)
- **Computer Account Reset** - Reset computer account password and domain relationship
- **Domain Trust Repair** - Validate and repair domain trust relationships
- **Host AD Cache Cleanup** - Clear host-specific AD cache and temporary files
- **Computer Certificate Management** - Reset computer certificates for AD authentication
- **Netlogon Service Reset** - Comprehensive Netlogon service troubleshooting
- **DNS Registration Repair** - Reset host DNS registration in Active Directory
- **Domain Membership Repair** - Complete domain membership troubleshooting workflow
- **Orphaned Object Cleanup** - Clean orphaned AD objects related to the host

## ⚡ Performance Optimization

### **System Performance Module** (`reset-system-performance.ps1`)
- **Comprehensive Performance Reset** - Full system optimization with profiles
- **Memory Management Optimization** - Memory allocation and virtual memory tuning
- **Disk Performance Optimization** - Disk cache and file system optimization
- **Service Optimization** - Service tuning for different performance profiles
- **System Cache Management** - Clear and optimize system-wide caches
- **Visual Effects Optimization** - Balance performance vs. appearance
- **Power Management Optimization** - Power plan optimization and settings

### **Performance Profiles**
- **🔥 Performance Profile**: Maximum speed optimization
- **⚖️ Balanced Profile**: Optimal performance/power balance
- **🔋 Power Saver Profile**: Energy efficiency focus

## 💾 Advanced Backup System

### **Backup Capabilities**
- **Standard Backups** - Registry and file system backup with manifests
- **Compressed Backups** - ZIP compression with optimal settings
- **Backup Verification** - Integrity testing and validation
- **Automated Cleanup** - Retention policies and cleanup management
- **Export Functionality** - External backup archiving
- **Restore Operations** - Complete backup restoration with verification

### **Backup Operations**
```powershell
# Create standard backup
New-ReSetBackup -BackupName "SystemSettings" -RegistryPaths @("HKLM:\Software\...")

# Create compressed backup
New-CompressedBackup -BackupName "CompleteSystem" -SourcePath "C:\Config"

# List and manage backups
Get-ReSetBackupList | Where-Object {$_.Age -gt 30}
Remove-ReSetBackup -RetentionDays 30 -Force

# Restore with verification
Restore-ReSetBackup -BackupName "SystemSettings" -Verify
```

## 📦 Windows Component Reset Modules

### 🌐 **Language & Regional** (2 modules)
- **`reset-language-settings.ps1`** - System locale, formats, keyboard layouts
- **`reset-datetime.ps1`** - Timezone, NTP settings, date/time formats

### 🖥️ **Display & Audio** (2 modules)
- **`reset-display.ps1`** - Resolution, DPI, colors, themes, visual effects
- **`reset-audio.ps1`** - Audio devices, volume, sound schemes, enhancements

### 🌐 **Network & Connectivity** (2 modules)
- **`reset-network.ps1`** - TCP/IP stack, DNS, firewall, network adapters
- **`reset-windows-update.ps1`** - Windows Update components, cache, settings

### 🔐 **Security & Privacy** (3 modules)
- **`reset-uac.ps1`** - User Account Control settings and policies
- **`reset-privacy.ps1`** - Privacy settings, app permissions, telemetry
- **`reset-defender.ps1`** - Windows Defender, firewall, security settings

### 🔍 **Search & Interface** (3 modules)
- **`reset-search.ps1`** - Windows Search indexing and configuration
- **`reset-startmenu.ps1`** - Start Menu, Taskbar, notification settings
- **`reset-shell.ps1`** - Windows Explorer, shell integration, context menus

### 📁 **File Management** (2 modules)
- **`reset-file-associations.ps1`** - File type associations and default programs
- **`reset-fonts.ps1`** - Font configuration, ClearType, text rendering

### ⚡ **Performance & Power** (2 modules)
- **`reset-power.ps1`** - Power management and sleep settings
- **`reset-performance.ps1`** - Performance counters and monitoring

### 🌐 **Applications & Store** (2 modules)
- **`reset-browser.ps1`** - Internet Explorer/Edge settings and cache
- **`reset-store.ps1`** - Microsoft Store cache and preferences

### ⌨️ **Input & Accessibility** (1 module)
- **`reset-input-devices.ps1`** - Mouse, keyboard, accessibility settings

### 🛠️ **System Components** (6 modules)
- **`reset-features.ps1`** - Windows features and capabilities
- **`reset-environment.ps1`** - Environment variables and PATH
- **`reset-registry.ps1`** - Registry operations and cleanup
- **`reset-services.ps1`** - Windows services management
- **`reset-advanced.ps1`** - Advanced system components
- **`reset-system-performance.ps1`** - Performance optimization

## 🚀 Quick Start

### **🎯 Interactive Mode**
```powershell
# Launch main toolkit
.\Reset-Manager.ps1

# Quick system health check
.\HealthCheck.ps1

# Active Directory troubleshooting
.\AD-Tools.ps1

# Advanced system cleanup
.\SystemCleanup.ps1
```

### **⚡ Command Line Usage**
```powershell
# Import utility module
Import-Module .\scripts\ReSetUtils.psm1

# System health assessment
$health = Get-SystemHealth
$report = Invoke-SystemReport

# Active Directory operations
$adStatus = Test-ActiveDirectoryConnectivity
if ($adStatus.Status -ne "Connected") {
    Reset-ActiveDirectoryCache -ClearKerberosTickets -ClearCredentialCache
}

# Performance optimization
Reset-SystemPerformance -Profile Performance -OptimizeMemory -OptimizeDisk
```

### **🔧 Individual Script Usage**
```powershell
# Run specific reset script
.\scripts\reset-network.ps1

# Run with Force parameter (skip confirmations)
.\scripts\reset-display.ps1 -Force

# Run multiple scripts
$scripts = @("reset-network", "reset-browser", "reset-performance")
foreach ($script in $scripts) {
    & ".\scripts\$script.ps1" -Force
}
```

## 🚀 Installation

### **Enhanced Installation Options**
```powershell
# Standard installation
.\Install.ps1

# Advanced installation with all features
.\Install.ps1 -InstallDependencies -CreateShortcuts -AddToPath

# Enterprise silent installation
.\Install.ps1 -InstallPath "C:\Tools\ReSet" -Silent -Force
```

### **Installation Features**
- **🔧 Automatic Dependencies**: PowerShell module installation
- **🖥️ Desktop Shortcuts**: Multiple tool shortcuts for easy access
- **📂 PATH Integration**: System-wide command accessibility
- **✅ Validation Testing**: Post-installation verification
- **🗑️ Uninstall Support**: Complete removal capabilities

## 📋 System Requirements

- **Operating System**: Windows 10/11 (x64 recommended)
- **PowerShell**: Version 5.0 or higher
- **Privileges**: Administrator rights required
- **.NET Framework**: 4.7.2 or higher
- **Memory**: 4GB RAM minimum (8GB recommended)
- **Storage**: 100MB for toolkit + backup space

## 🔐 Enterprise Features

### **Security & Compliance**
- **🛡️ Administrator Enforcement**: Mandatory elevation for all operations
- **💾 Backup-First Philosophy**: Automatic backup before changes
- **📋 Comprehensive Logging**: Complete audit trails for compliance
- **🔄 Rollback Capabilities**: Full operation reversal support
- **✅ Operation Validation**: Pre and post-operation verification

### **Active Directory Integration**
- **🌐 Domain Management**: Complete domain troubleshooting workflows
- **🔐 Kerberos Support**: Advanced authentication troubleshooting
- **🏢 Group Policy Integration**: GP cache management and refresh
- **💻 Computer Account Management**: Host computer domain operations
- **🔧 Trust Relationship Repair**: Domain trust validation and repair

### **Advanced Administration**
- **📊 System Health Monitoring**: Real-time health assessment
- **⚡ Performance Optimization**: Multiple optimization profiles
- **🗂️ Backup Management**: Enterprise backup policies and retention
- **📈 Reporting**: HTML reports for management visibility
- **🔄 Automation Support**: PowerShell DSC compatibility

## 📝 Documentation

- **📖 User Guide**: [README.md](README.md) - Complete usage documentation
- **🔧 Technical Reference**: [reference.md](reference.md) - Detailed technical documentation  
- **📋 Enhancement Summary**: [ENHANCEMENT_SUMMARY.md](ENHANCEMENT_SUMMARY.md) - Version 2.0 improvements
- **📄 License**: [LICENSE](LICENSE) - MIT License information

## 🤝 Support & Contributing

### **Getting Help**
- **🐛 Bug Reports**: [GitHub Issues](https://github.com/jomardyan/ReSet2/issues)
- **💡 Feature Requests**: [GitHub Discussions](https://github.com/jomardyan/ReSet2/discussions)
- **📖 Documentation**: [Wiki](https://github.com/jomardyan/ReSet2/wiki)

### **Contributing**
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**⭐ Star this repository if you find it helpful!**

**Windows Reset Toolkit 2.0** - Professional Windows administration and troubleshooting suite  
Made with ❤️ by [jomardyan](https://github.com/jomardyan)
- **`reset-windows-update.ps1`** - Reset Windows Update cache, services, components (20 functions)

### 🔐 Security & Privacy (35 functions)
- **`reset-uac.ps1`** - Reset User Account Control settings (8 functions)
- **`reset-privacy.ps1`** - Reset privacy settings and app permissions (15 functions)
- **`reset-defender.ps1`** - Reset Windows Defender configuration (12 functions)

### 🔍 Search & Interface (30 functions)
- **`reset-search.ps1`** - Reset Windows Search and indexing (8 functions)
- **`reset-startmenu.ps1`** - Reset Start Menu and Taskbar settings (10 functions)
- **`reset-shell.ps1`** - Reset Windows Explorer settings (12 functions)

### 📁 File Management (18 functions)
- **`reset-file-associations.ps1`** - Reset file type associations (8 functions)
- **`reset-fonts.ps1`** - Reset font settings and ClearType (10 functions)

### ⚡ Performance & Power (11 functions)
- **`reset-power.ps1`** - Reset power management settings (6 functions)
- **`reset-performance.ps1`** - Reset performance counters (5 functions)

### 🌐 Applications & Store (10 functions)
- **`reset-browser.ps1`** - Reset IE/Edge settings (4 functions)
- **`reset-store.ps1`** - Reset Microsoft Store configuration (6 functions)

### ⌨️ Input & Accessibility (8 functions)
- **`reset-input-devices.ps1`** - Reset mouse, keyboard, accessibility (8 functions)

### 🛠️ System Components (15 functions)
- **`reset-features.ps1`** - Reset Windows optional features (5 functions)
- **`reset-environment.ps1`** - Reset environment variables (4 functions)
- **`reset-registry.ps1`** - Registry cleanup and reset (6 functions)

### ⚡ Advanced & Services (65 functions)
- **`reset-services.ps1`** - Reset Windows services and startup programs (15 functions)
- **`reset-security.ps1`** - Advanced security and system settings (10 functions)
- **`reset-advanced.ps1`** - Advanced system components and specialized resets (25 functions)
- **Plus additional specialized functions** (15 functions)

## 🏗️ Project Structure

```
ReSet/
├── 📁 scripts/              # All reset scripts
│   ├── ReSetUtils.psm1     # Utility module with common functions
│   ├── reset-language-settings.ps1
│   ├── reset-datetime.ps1
│   ├── reset-display.ps1
│   ├── reset-audio.ps1
│   ├── reset-network.ps1
│   ├── reset-windows-update.ps1
│   ├── reset-uac.ps1
│   ├── reset-privacy.ps1
│   ├── reset-defender.ps1
│   ├── reset-search.ps1
│   ├── reset-startmenu.ps1
│   ├── reset-shell.ps1
│   ├── reset-file-associations.ps1
│   ├── reset-fonts.ps1
│   ├── reset-power.ps1
│   ├── reset-performance.ps1
│   ├── reset-browser.ps1
│   ├── reset-store.ps1
│   ├── reset-input-devices.ps1
│   ├── reset-features.ps1
│   ├── reset-environment.ps1
│   ├── reset-registry.ps1
│   ├── reset-services.ps1
│   ├── reset-security.ps1
│   └── reset-advanced.ps1
├── 📁 logs/                # Operation logs
├── 📁 backups/             # Automatic backups
├── 📁 docs/                # Documentation
├── Reset-Manager.ps1       # Main interactive CLI
├── Install.ps1             # Installation script
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites
- **OS**: Windows 10/11 (64-bit recommended)
- **PowerShell**: Version 5.0 or higher
- **Privileges**: Administrator rights required

### Installation

#### Option 1: Quick Install
```powershell
# Download and run installer
.\Install.ps1
```

#### Option 2: Manual Setup
1. Extract toolkit to desired location
2. Run PowerShell as Administrator
3. Navigate to toolkit directory
4. Execute: `.\Reset-Manager.ps1`

### Usage Examples

#### Interactive Menu (Recommended)
```powershell
# Launch interactive interface
.\Reset-Manager.ps1
```

#### Command Line Usage
```powershell
# Reset specific components
.\Reset-Manager.ps1 -Scripts "reset-display","reset-audio"

# List all available scripts
.\Reset-Manager.ps1 -ListScripts

# Silent mode with no backups
.\Reset-Manager.ps1 -Scripts "reset-network" -Silent -NoBackup

# Force execution without confirmations
.\Reset-Manager.ps1 -Scripts "reset-privacy" -Force
```

#### Individual Script Execution
```powershell
# Run single script with parameters
.\scripts\reset-display.ps1 -Silent -CreateBackup

# Run with custom backup path
.\scripts\reset-network.ps1 -BackupPath "D:\MyBackups"
```

## 🎨 Interactive CLI Features

The Reset-Manager provides a rich, user-friendly interface:

- **📋 Categorized Menus**: Scripts organized by function
- **🎨 Color-Coded Output**: Clear visual feedback
- **📊 Progress Tracking**: Real-time progress bars
- **🛡️ Safety Prompts**: Confirmation dialogs for destructive operations
- **💾 Backup Management**: Built-in backup and restore functionality
- **📝 Operation Logging**: Detailed logs of all operations

## ⚠️ Important Safety Information

### Before Running Scripts
- **🔴 Administrator Rights**: All scripts require administrator privileges
- **💾 Create Backups**: Always create system restore point before major resets
- **🔄 System Restart**: Some resets may require system restart
- **⚡ Data Loss**: Some scripts may clear user preferences and customizations
- **🧪 Test Environment**: Test scripts in a safe environment first

### Backup Strategy
- Automatic registry backups before changes
- Configuration files copied to backup directory  
- Restore points created for system-level changes
- Manual backup and restore functionality available

## 📝 Logging System

All operations are logged with timestamps:

```
logs/reset-operations-YYYY-MM-DD.log
```

**Log Levels:**
- **INFO**: General operation information
- **WARN**: Warnings about potential issues  
- **ERROR**: Script execution errors
- **SUCCESS**: Successful operation completion

## 🔄 Backup and Restore

### Automatic Backups
Each script automatically creates backups before making changes:
- Registry settings exported to `.reg` files
- Configuration files copied to timestamped folders
- Backup manifests with operation details

### Manual Restore
```powershell
# Restore from specific backup
.\scripts\restore-backup.ps1 -BackupDate "2024-01-15" -Category "display"

# View available backups
.\Reset-Manager.ps1 -ShowBackups
```

## 🛠️ Advanced Usage

### Automation and Scripting
```powershell
# Unattended execution
.\Reset-Manager.ps1 -Scripts "reset-network","reset-display" -Silent -Force

# Custom logging level
.\Reset-Manager.ps1 -Scripts "reset-audio" -LogLevel "DEBUG"

# Batch processing entire categories
.\Reset-Manager.ps1 -Categories "Security & Privacy"
```

### Integration with Group Policy
The toolkit can be integrated with Group Policy for enterprise deployment:
- Deploy via logon scripts
- Schedule via Task Scheduler
- Integrate with SCCM/Intune

## 📊 Success Metrics

After running reset operations, you'll see detailed summaries:
- Number of functions executed
- Success/failure rates
- Time taken per operation
- Backup locations
- Restart requirements

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 🐛 Support & Troubleshooting

### Common Issues
- **Access Denied**: Run PowerShell as Administrator
- **Execution Policy**: Run `Set-ExecutionPolicy Bypass -Scope Process`
- **Script Not Found**: Verify file paths and directory structure
- **Backup Failed**: Check disk space and permissions

### Getting Help
- **Documentation**: [GitHub Wiki](https://github.com/jomardyan/ReSet2/wiki)
- **Issues**: [GitHub Issues](https://github.com/jomardyan/ReSet2/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jomardyan/ReSet2/discussions)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 Version History

### v1.0.0 (Current)
- ✅ 25 PowerShell reset scripts
- ✅ 276+ individual reset functions  
- ✅ Interactive CLI interface
- ✅ Comprehensive backup system
- ✅ Detailed logging and error handling
- ✅ Windows 10/11 support
- ✅ Full automation capabilities

## 🔗 Related Projects

- [System-Extract](https://github.com/jomardyan/System-Extract) - System information extraction
- [script-runner-ide](https://github.com/jomardyan/script-runner-ide) - Script development environment

---

**⭐ Star this repository if it helped you reset your Windows settings!**

**Made with ❤️ by [jomardyan](https://github.com/jomardyan)**

*Windows Reset Toolkit - Because sometimes you need a fresh start* 🔄