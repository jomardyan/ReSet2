# Windows Reset Toolkit 2.0 - Technical Reference

> Professional PowerShell-based Windows administration and troubleshooting suite with Active Directory integration.

## 🎯 Technical Overview

**ReSet Toolkit 2.0** is an enterprise-grade PowerShell module collection designed for comprehensive Windows system reset, troubleshooting, and maintenance. The toolkit provides 75+ specialized functions across 29 modules, featuring Advanced Active Directory integration, comprehensive backup systems, and professional admin tools.

## 🏗️ Architecture & Design

### **Core Architecture**
- **PowerShell 5.0+ Framework**: Modern PowerShell module architecture
- **Modular Design**: 29 specialized script modules with focused functionality
- **Enterprise Integration**: Active Directory domain management and host cleanup
- **Professional Logging**: Comprehensive audit trails and operation tracking
- **Advanced Backup System**: Multi-format backup with compression and verification

### **Technical Stack**
- **Language**: PowerShell 5.0+
- **Platform**: Windows 10/11 (x64)
- **Requirements**: Administrator privileges, .NET Framework 4.7.2+
- **Architecture**: Module-based with central utility framework
- **Integration**: AD, Group Policy, WMI, Registry, Services

## 📊 Function Inventory

### **Core Statistics**
- **Total Functions**: 75+ specialized functions
- **Reset Modules**: 27 Windows component reset modules  
- **Utility Functions**: 26 infrastructure and support functions
- **AD Functions**: 15 Active Directory management functions
- **Backup Functions**: 6 comprehensive backup/restore functions
- **Admin Tools**: 3 standalone diagnostic utilities

## 📁 Enhanced Project Structure

```
ReSet2/
├── 📜 Reset-Manager.ps1              # Main interactive CLI interface
├── 📜 Install.ps1                    # Enhanced installation with multi-tool setup
├── 📜 HealthCheck.ps1               # Standalone system health checker
├── 📜 AD-Tools.ps1                  # Interactive AD troubleshooting toolkit
├── 📜 SystemCleanup.ps1             # Advanced system cleanup utility
├── 📜 README.md                     # User documentation
├── 📜 ENHANCEMENT_SUMMARY.md        # Technical enhancement details
├── 📁 scripts/                      # Core PowerShell modules
│   ├── 📜 ReSetUtils.psm1          # Central utility module (26 functions)
│   ├── 📜 reset-active-directory.ps1    # AD management (7 functions)
│   ├── 📜 reset-ad-host-cleanup.ps1     # Host AD cleanup (9 functions)
│   ├── 📜 reset-system-performance.ps1  # Performance optimization (8 functions)
│   ├── 📜 reset-language-settings.ps1   # Language & regional settings
│   ├── 📜 reset-datetime.ps1            # Time zone & date settings
│   ├── 📜 reset-display.ps1             # Display configuration
│   ├── 📜 reset-audio.ps1               # Audio device settings
│   ├── 📜 reset-network.ps1             # Network adapter configuration
│   ├── 📜 reset-windows-update.ps1      # Windows Update components
│   ├── 📜 reset-uac.ps1                 # User Account Control
│   ├── 📜 reset-privacy.ps1             # Privacy settings
│   ├── 📜 reset-defender.ps1            # Windows Defender
│   ├── 📜 reset-search.ps1              # Windows Search indexing
│   ├── 📜 reset-startmenu.ps1           # Start Menu & Taskbar
│   ├── 📜 reset-shell.ps1               # Windows Shell & Explorer
│   ├── 📜 reset-file-associations.ps1   # File type associations
│   ├── 📜 reset-fonts.ps1               # Font configuration
│   ├── 📜 reset-power.ps1               # Power management
│   ├── 📜 reset-performance.ps1         # Performance counters
│   ├── 📜 reset-browser.ps1             # Browser settings
│   ├── 📜 reset-store.ps1               # Microsoft Store
│   ├── 📜 reset-input-devices.ps1       # Input device settings
│   ├── 📜 reset-features.ps1            # Windows features
│   ├── 📜 reset-environment.ps1         # Environment variables
│   ├── 📜 reset-registry.ps1            # Registry operations
│   ├── 📜 reset-services.ps1            # Windows services
│   └── 📜 reset-advanced.ps1            # Advanced system operations
├── 📁 logs/                         # Operation logs and audit trails
├── 📁 backups/                      # Backup storage with manifests
├── 📁 docs/                         # Technical documentation
├── 📁 gui/                          # Future GUI components
└── 📁 config/                       # Configuration management
```

## 🔧 Core Module: ReSetUtils.psm1

### **Infrastructure Functions** (26 total)
```powershell
# Logging & Operations
Write-ReSetLog                    # Comprehensive logging system
Start-ReSetOperation             # Operation tracking and audit
Complete-ReSetOperation          # Operation completion and status

# Backup & Restore System
New-ReSetBackup                  # Standard backup creation
New-CompressedBackup             # Compressed backup with encryption placeholder
Restore-ReSetBackup              # Comprehensive backup restoration
Get-ReSetBackupList              # Backup inventory management
Remove-ReSetBackup               # Automated cleanup with retention
Test-ReSetBackup                 # Backup integrity verification
Export-ReSetBackup               # Backup export to external locations

# System Utilities
Test-IsAdmin                     # Administrator privilege validation
Assert-AdminRights              # Rights enforcement
Test-WindowsVersion             # OS compatibility checking
Confirm-ReSetOperation          # User confirmation prompts

# Registry & Service Management
Set-RegistryValue               # Safe registry modification
Remove-RegistryValue            # Registry value removal
Remove-RegistryKey              # Registry key operations
Restart-WindowsService          # Service lifecycle management

# User Interface
Write-ReSetHeader               # Professional headers
Write-ProgressStep              # Progress indication
Show-ReSetMenu                  # Interactive menu system

# Advanced Features
Get-SystemHealth                # Comprehensive health monitoring
Invoke-AdvancedCleanup          # Multi-target system cleanup
Test-ActiveDirectoryConnectivity # AD connectivity testing
Reset-ActiveDirectoryCache      # AD cache management
Invoke-SystemReport             # HTML report generation
```

## 🌐 Active Directory Integration

### **Domain Management** (reset-active-directory.ps1)
```powershell
Reset-DomainConnectivity        # Domain connection repair
Reset-ADCredentials             # Credential cache management
Reset-GroupPolicyCache          # GP cache clearing and refresh
Reset-KerberosAuthentication    # Kerberos ticket management
Reset-ADDNSSettings             # AD DNS configuration
Reset-ADServices                # AD service orchestration
Reset-ADClientCache             # Client-side cache cleanup
```

### **Host Computer Cleanup** (reset-ad-host-cleanup.ps1)
```powershell
Reset-ComputerAccount           # Computer account password reset
Reset-DomainTrust               # Trust relationship repair
Reset-HostADCache               # Host-specific cache cleanup
Reset-ComputerCertificates      # Computer certificate management
Reset-HostNetlogon             # Netlogon service reset
Reset-HostDNSRegistration       # DNS registration repair
Repair-DomainMembership         # Comprehensive domain repair
Clean-OrphanedADObjects         # Orphaned object cleanup
```

## ⚡ Performance Optimization

### **System Performance Module** (reset-system-performance.ps1)
```powershell
Reset-SystemPerformance        # Comprehensive performance optimization
Reset-MemoryManagement         # Memory allocation optimization
Reset-DiskOptimization          # Disk cache and file system tuning
Reset-SystemServices            # Service optimization profiles
Reset-SystemCache               # System-wide cache management
Reset-VisualEffects             # Visual effects optimization
Reset-PowerManagement           # Power plan optimization
Set-SystemPerformanceProfile   # Performance profile application
```

### **Performance Profiles**
- **Performance Profile**: Maximum speed optimization
- **Balanced Profile**: Optimal performance/power balance  
- **Power Saver Profile**: Energy efficiency focus

## 🛠️ Standalone Admin Tools

### **HealthCheck.ps1** - System Health Assessment
- Real-time system file integrity checking
- Registry health validation
- Disk space and performance monitoring
- Critical service status verification
- Network connectivity testing
- Memory usage analysis
- HTML report generation

### **AD-Tools.ps1** - Active Directory Troubleshooting
- Interactive AD connectivity testing
- Kerberos ticket management
- Credential cache clearing
- DNS cache management
- Complete AD reset workflows

### **SystemCleanup.ps1** - Advanced System Cleanup
- Selective cleanup options
- Temporary file management
- Browser cache clearing
- Event log cleanup
- Prefetch optimization
- Windows Update cache management

## 💾 Enhanced Backup System

### **Backup Capabilities**
```powershell
# Standard Operations
New-ReSetBackup -BackupName "Settings" -RegistryPaths @("HKLM:\Software\...")

# Compressed Backups
New-CompressedBackup -BackupName "SystemConfig" -SourcePath "C:\Config"

# Restore Operations
Restore-ReSetBackup -BackupName "Settings" -Verify

# Management Operations
Get-ReSetBackupList | Where-Object {$_.Name -like "System*"}
Remove-ReSetBackup -RetentionDays 30 -Force
Test-ReSetBackup -BackupName "CriticalSettings"
Export-ReSetBackup -BackupName "Settings" -ExportPath "D:\Archive" -Compress
```

### **Backup Features**
- **Registry & File System**: Complete configuration backup
- **Compression Support**: ZIP compression with optimal settings
- **Integrity Verification**: Backup validation and testing
- **Retention Management**: Automated cleanup policies
- **Export Capabilities**: External archive creation
- **Manifest System**: Detailed backup cataloging

## 🔐 Security & Enterprise Features

### **Security Model**
- **Administrator Enforcement**: Mandatory elevation for all operations
- **Backup-First Philosophy**: Automatic backup before changes
- **Operation Auditing**: Comprehensive logging and tracking
- **Confirmation Prompts**: User validation for destructive operations
- **Rollback Capabilities**: Complete operation reversal

### **Enterprise Integration**
- **Active Directory Support**: Domain-joined system management
- **Group Policy Integration**: GP cache management and refresh
- **Service Management**: Enterprise service optimization
- **Certificate Handling**: Computer certificate management
- **DNS Integration**: Enterprise DNS registration and cleanup

## 📋 Usage Patterns

### **Interactive Usage**
```powershell
# Launch main interface
.\Reset-Manager.ps1

# Quick health check
.\HealthCheck.ps1

# AD troubleshooting
.\AD-Tools.ps1

# System maintenance
.\SystemCleanup.ps1
```

### **Programmatic Usage**
```powershell
# Import module
Import-Module .\scripts\ReSetUtils.psm1

# System health assessment
$health = Get-SystemHealth
$report = Invoke-SystemReport

# AD operations
$adStatus = Test-ActiveDirectoryConnectivity
if ($adStatus.Status -ne "Connected") {
    Reset-ActiveDirectoryCache -ClearKerberosTickets -ClearCredentialCache
}

# Performance optimization
Reset-SystemPerformance -Profile Performance -OptimizeMemory -OptimizeDisk
```

### **Automation & Scripting**
```powershell
# Batch operations
$scripts = @("reset-network", "reset-dns", "reset-browser")
foreach ($script in $scripts) {
    & ".\scripts\$script.ps1" -Force -Silent
}

# Scheduled maintenance
$backupResult = New-ReSetBackup -BackupName "DailyMaintenance"
Reset-SystemCache -Force
Invoke-AdvancedCleanup -IncludeTempFiles -IncludeBrowserCache
```

## 🔍 Logging & Monitoring

### **Comprehensive Logging**
- **Operation Tracking**: Start/completion timestamps
- **Error Handling**: Detailed error capture and reporting
- **Audit Trails**: Complete operation history
- **Performance Metrics**: System health and performance data
- **Security Events**: Privilege usage and sensitive operations

### **Log Locations**
```
logs/
├── reset-operations-YYYY-MM-DD.log    # Daily operation logs
├── system-health-YYYY-MM-DD.log       # Health monitoring logs
├── backup-operations-YYYY-MM-DD.log   # Backup system logs
└── error-YYYY-MM-DD.log               # Error and exception logs
```

## 🚀 Installation & Deployment

### **Enhanced Installation Process**
```powershell
# Standard installation
.\Install.ps1

# Advanced installation with dependencies
.\Install.ps1 -InstallDependencies -CreateShortcuts

# Enterprise deployment
.\Install.ps1 -InstallPath "C:\Tools\ReSet" -AddToPath -Silent
```

### **Installation Features**
- **Automatic dependency detection**: PowerShell module installation
- **Desktop shortcut creation**: Multiple tool shortcuts
- **PATH integration**: System-wide accessibility
- **Validation testing**: Post-installation verification
- **Uninstallation support**: Complete removal capabilities

## 📈 Performance & Scalability

### **Optimization Features**
- **Modular Loading**: On-demand module importing
- **Efficient Operations**: Minimal system impact
- **Batch Processing**: Multiple operation handling
- **Background Operations**: Non-blocking execution
- **Resource Management**: Memory and CPU optimization

### **Scalability Considerations**
- **Enterprise Deployment**: Multi-system management
- **Domain Integration**: Centralized AD management
- **Automation Ready**: PowerShell DSC compatibility
- **Monitoring Integration**: SCOM/monitoring tool support
- **Reporting Capabilities**: Management dashboard data

## 🔧 Configuration Management

### **Advanced Configuration** ($Script:Config)
```powershell
@{
    CompressionEnabled = $true      # Enable backup compression
    EncryptionEnabled = $false      # Encryption placeholder
    ADIntegration = $true          # Active Directory features
    PerformanceMetrics = $true     # Detailed performance monitoring
    MaxBackupAge = 30              # Backup retention (days)
    LogLevel = "INFO"              # Logging verbosity
    AutoCleanup = $true           # Automatic maintenance
    ReportsPath = ".\reports"      # Report storage location
    TempPath = ".\temp"           # Temporary file location
}
```

### **Customization Options**
- **Operation Profiles**: Performance, Balanced, Power Saver
- **Backup Policies**: Retention, compression, location
- **Logging Levels**: Verbose, Info, Warning, Error
- **UI Preferences**: Colors, prompts, confirmation levels
- **Integration Settings**: AD, Group Policy, monitoring

## 🎯 Best Practices

### **Usage Guidelines**
1. **Always run as Administrator**: Required for system-level operations
2. **Create backups first**: Use backup system before major changes
3. **Test in development**: Validate operations in test environments
4. **Monitor logs**: Review operation logs for issues
5. **Follow change management**: Document and track changes

### **Enterprise Deployment**
1. **Pilot testing**: Test with limited user groups
2. **Backup strategies**: Implement comprehensive backup policies
3. **Monitoring integration**: Connect to enterprise monitoring
4. **Documentation**: Maintain operation procedures
5. **Training**: Educate administrators on toolkit usage

---

**ReSet Toolkit 2.0 - Professional Windows Administration Suite**  
*Enterprise-grade system reset, Active Directory tools, and advanced backup capabilities*

```markdown name=README.md
# Windows Settings Reset Toolkit (ReSet)

> A comprehensive collection of Windows configuration reset scripts for system administrators, IT professionals, and power users.

## 🎯 Overview

**ReSet** is a powerful Windows settings reset toolkit designed to quickly restore various Windows configurations to their default states. This utility collection addresses common scenarios where users need to reset specific system settings without performing a full system restore or reinstallation.

## 🚀 Purpose & Use Cases

- **🔧 System Administration**: IT professionals managing multiple Windows machines
- **🛠️ Troubleshooting**: Resolving configuration conflicts and corrupted settings
- **✨ Clean Slate Setup**: Preparing systems for new users or deployments
- **🔒 Privacy Reset**: Clearing personalized settings and returning to defaults
- **⚡ Performance Optimization**: Resetting settings that may impact system performance

## 👥 Target Audience

- System Administrators
- IT Support Technicians
- Power Users
- Developers setting up clean environments
- Users experiencing configuration-related issues

## 📦 Reset Scripts Collection

### 🌐 Language & Regional Settings

#### 1. **Language & Regional Settings Reset**
```batch
scripts/reset-language-settings.bat
```
- Reset system locale to default
- Clear custom date/time formats
- Reset number and currency formats
- Restore default keyboard layouts

#### 2. **Time Zone & Date Reset**
```batch
scripts/reset-datetime.bat
```
- Reset to automatic time zone detection
- Clear custom time servers
- Restore default date/time display formats
- Reset calendar preferences

### 🖥️ Display & Audio

#### 3. **Display Settings Reset**
```batch
scripts/reset-display.bat
```
- Reset screen resolution to recommended
- Clear custom DPI scaling
- Reset monitor arrangements
- Restore default color profiles

#### 4. **Audio Settings Reset**
```batch
scripts/reset-audio.bat
```
- Reset default playback/recording devices
- Clear custom audio enhancements
- Reset volume levels to default
- Restore system sounds scheme

### 🌐 Network & Connectivity

#### 5. **Network Adapter Reset**
```batch
scripts/reset-network.bat
```
- Reset TCP/IP stack
- Clear DNS cache and settings
- Reset Windows Firewall rules
- Restore network adapter configurations

#### 6. **Windows Update Reset**
```batch
scripts/reset-windows-update.bat
```
- Clear Windows Update cache
- Reset update agent components
- Restore automatic update settings
- Clear failed update history

### 🔐 Security & Privacy

#### 7. **User Account Control (UAC) Reset**
```batch
scripts/reset-uac.bat
```
- Reset UAC to default level
- Clear UAC policy overrides
- Restore admin approval mode
- Reset elevation prompts

#### 8. **Privacy Settings Reset**
```batch
scripts/reset-privacy.bat
```
- Reset app permissions
- Clear location history
- Reset microphone/camera access
- Restore default telemetry settings

#### 9. **Windows Defender Reset**
```batch
scripts/reset-defender.bat
```
- Reset Windows Defender settings
- Clear quarantine and exclusions
- Restore real-time protection
- Reset firewall configurations

### 🔍 Search & Interface

#### 10. **Windows Search Reset**
```batch
scripts/reset-search.bat
```
- Rebuild search index
- Reset search options
- Clear search history
- Restore default search locations

#### 11. **Start Menu & Taskbar Reset**
```batch
scripts/reset-startmenu.bat
```
- Reset Start Menu layout
- Clear pinned items
- Restore default taskbar settings
- Reset notification area icons

#### 12. **Windows Shell Reset**
```batch
scripts/reset-shell.bat
```
- Reset Windows Explorer settings
- Clear folder view preferences
- Restore default shell associations
- Reset context menu items

### 📁 File Management

#### 13. **File Associations Reset**
```batch
scripts/reset-file-associations.bat
```
- Reset default programs
- Clear custom file type associations
- Restore Windows default handlers
- Reset protocol associations

#### 14. **Fonts & Text Settings Reset**
```batch
scripts/reset-fonts.bat
```
- Reset system fonts to default
- Clear custom font installations
- Restore text scaling settings
- Reset ClearType configuration

### ⚡ Performance & Power

#### 15. **Power Management Reset**
```batch
scripts/reset-power.bat
```
- Reset power plans to default
- Clear custom power settings
- Restore sleep/hibernate options
- Reset display timeout settings

#### 16. **Performance Counters Reset**
```batch
scripts/reset-performance.bat
```
- Rebuild performance counter registry
- Reset performance monitoring
- Clear corrupted counter data
- Restore system monitoring

### 🌐 Applications & Store

#### 17. **Internet Explorer/Edge Reset**
```batch
scripts/reset-browser.bat
```
- Clear browsing data
- Reset homepage and search engine
- Remove extensions and add-ons
- Restore default security settings

#### 18. **Windows Store Reset**
```batch
scripts/reset-store.bat
```
- Clear Microsoft Store cache
- Reset store preferences
- Restore default store settings
- Clear download history

### ⌨️ Input & Accessibility

#### 19. **Mouse & Keyboard Reset**
```batch
scripts/reset-input-devices.bat
```
- Reset mouse sensitivity and settings
- Clear custom keyboard shortcuts
- Restore default pointer schemes
- Reset accessibility options

### 🛠️ System Components

#### 20. **Windows Features Reset**
```batch
scripts/reset-features.bat
```
- Reset optional Windows features
- Clear custom feature installations
- Restore default component states
- Reset Windows capabilities

#### 21. **System Environment Reset**
```batch
scripts/reset-environment.bat
```
- Clear custom environment variables
- Reset PATH modifications
- Restore default system variables
- Clear user-specific settings

#### 22. **Registry Cleanup & Reset**
```batch
scripts/reset-registry.bat
```
- Reset specific registry keys
- Clear orphaned entries
- Restore default registry values
- Backup before modifications

## 🎛️ Implementation Features

- **💾 Backup Creation**: Each script creates backups before making changes
- **🎯 Selective Reset**: Individual script execution or batch processing
- **🛡️ Safety Checks**: Verification prompts and rollback options
- **📋 Logging**: Detailed operation logs for troubleshooting
- **🖥️ GUI Interface**: Optional graphical interface for non-technical users
- **⌨️ Command Line Support**: Full CLI functionality for automation

## 📋 Prerequisites

### System Requirements
- **OS**: Windows 10/11 (64-bit recommended)
- **Privileges**: Administrator rights required
- **PowerShell**: Version 5.0 or higher
- **Framework**: .NET Framework 4.7.2+

### Before You Begin
- Create a system restore point
- Close all unnecessary applications
- Ensure you have administrator privileges
- Review which settings you want to reset

## 🚀 Quick Start

### Option 1: Individual Script Execution
```cmd
# Run as Administrator
cd ReSet/scripts
reset-language-settings.bat
```

### Option 2: Batch Processing
```cmd
# Run multiple scripts
batch-reset.bat --scripts "language,datetime,display"
```

### Option 3: GUI Interface
```cmd
# Launch graphical interface
reset-toolkit-gui.exe
```

## 📁 Project Structure

```
ReSet/
├── 📁 scripts/
│   ├── reset-language-settings.bat
│   ├── reset-datetime.bat
│   ├── reset-display.bat
│   ├── reset-audio.bat
│   ├── reset-network.bat
│   ├── reset-windows-update.bat
│   ├── reset-uac.bat
│   ├── reset-search.bat
│   ├── reset-startmenu.bat
│   ├── reset-file-associations.bat
│   ├── reset-privacy.bat
│   ├── reset-power.bat
│   ├── reset-defender.bat
│   ├── reset-browser.bat
│   ├── reset-store.bat
│   ├── reset-fonts.bat
│   ├── reset-input-devices.bat
│   ├── reset-features.bat
│   ├── reset-environment.bat
│   ├── reset-registry.bat
│   ├── reset-shell.bat
│   └── reset-performance.bat
├── 📁 gui/
│   └── reset-toolkit-gui.exe
├── 📁 logs/
├── 📁 backups/
├── 📁 docs/
├── batch-reset.bat
├── install.bat
└── README.md
```

## 🔧 Usage Examples

### Reset Language Settings
```cmd
# Basic reset
scripts\reset-language-settings.bat

# With backup verification
scripts\reset-language-settings.bat --verify-backup

# Silent mode (no prompts)
scripts\reset-language-settings.bat --silent
```

### Reset Multiple Categories
```cmd
# Reset display and audio together
batch-reset.bat --categories "display,audio"

# Reset all network-related settings
batch-reset.bat --categories "network,browser,store"
```

### Advanced Options
```cmd
# Create restore point before reset
batch-reset.bat --create-restore-point --categories "all"

# Custom backup location
scripts\reset-display.bat --backup-path "D:\ReSet-Backups"
```

## ⚠️ Important Warnings

- **🔴 Administrator Rights**: All scripts require administrator privileges
- **💾 Backup First**: Always create backups before running scripts
- **🔄 System Restart**: Some resets may require system restart
- **⚡ Data Loss**: Some scripts may clear user preferences and customizations
- **🧪 Test Environment**: Test scripts in a safe environment first

## 📝 Logging

All operations are logged to:
```
logs/reset-operations-YYYY-MM-DD.log
```

Log levels:
- **INFO**: General operation information
- **WARN**: Warnings about potential issues
- **ERROR**: Script execution errors
- **SUCCESS**: Successful operation completion

## 🔄 Rollback Options

### Automatic Backups
- Registry settings backed up before changes
- Configuration files copied to backup directory
- Restore points created for system-level changes

### Manual Rollback
```cmd
# Restore from specific backup
restore-backup.bat --date "2024-01-15" --category "display"

# Restore all settings from backup
restore-backup.bat --restore-all --date "2024-01-15"
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Bug Reports & Feature Requests

Please use GitHub Issues to report bugs or request new features:
- [Report a Bug](https://github.com/jomardyan/ReSet/issues/new?template=bug_report.md)
- [Request a Feature](https://github.com/jomardyan/ReSet/issues/new?template=feature_request.md)

## 📞 Support

- **Documentation**: [Wiki](https://github.com/jomardyan/ReSet/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/jomardyan/ReSet/discussions)
- **Issues**: [GitHub Issues](https://github.com/jomardyan/ReSet/issues)

## 🔗 Related Projects

- [win-regional-reset](https://github.com/jomardyan/win-regional-reset) - Specialized regional settings reset
- [System-Extract](https://github.com/jomardyan/System-Extract) - System information extraction tools
- [script-runner-ide](https://github.com/jomardyan/script-runner-ide) - Script development environment

---

**⭐ Star this repository if you find it helpful!**

Made with ❤️ by [jomardyan](https://github.com/jomardyan)
```

This comprehensive Markdown documentation provides:

1. **Professional README structure** with proper formatting
2. **Clear categorization** of all 22 reset scripts
3. **Detailed feature descriptions** for each script
4. **Usage examples** and command-line options
5. **Safety warnings** and best practices
6. **Project structure** and file organization
7. **Contributing guidelines** and support information
8. **Links to your related repositories**

The documentation is ready to use as your main README.md file and provides users with everything they need to understand and use your Windows Settings Reset Toolkit effectively.

# Windows Settings Reset Toolkit (ReSet)

> A comprehensive collection of Windows configuration reset scripts for system administrators, IT professionals, and power users.

## 🎯 Overview

**ReSet** is a powerful Windows settings reset toolkit designed to quickly restore various Windows configurations to their default states. This utility collection addresses common scenarios where users need to reset specific system settings without performing a full system restore or reinstallation.

## 🚀 Purpose & Use Cases

- **🔧 System Administration**: IT professionals managing multiple Windows machines
- **🛠️ Troubleshooting**: Resolving configuration conflicts and corrupted settings
- **✨ Clean Slate Setup**: Preparing systems for new users or deployments
- **🔒 Privacy Reset**: Clearing personalized settings and returning to defaults
- **⚡ Performance Optimization**: Resetting settings that may impact system performance

## 👥 Target Audience

- System Administrators
- IT Support Technicians
- Power Users
- Developers setting up clean environments
- Users experiencing configuration-related issues

## 📦 Reset Scripts Collection

### 🌐 Language & Regional Settings

#### 1. **Language & Regional Settings Reset**
```batch
scripts/reset-language-settings.bat
```
- Reset system locale to default
- Clear custom date/time formats
- Reset number and currency formats
- Restore default keyboard layouts

#### 2. **Time Zone & Date Reset**
```batch
scripts/reset-datetime.bat
```
- Reset to automatic time zone detection
- Clear custom time servers
- Restore default date/time display formats
- Reset calendar preferences

### 🖥️ Display & Audio

#### 3. **Display Settings Reset**
```batch
scripts/reset-display.bat
```
- Reset screen resolution to recommended
- Clear custom DPI scaling
- Reset monitor arrangements
- Restore default color profiles

#### 4. **Audio Settings Reset**
```batch
scripts/reset-audio.bat
```
- Reset default playback/recording devices
- Clear custom audio enhancements
- Reset volume levels to default
- Restore system sounds scheme

### 🌐 Network & Connectivity

#### 5. **Network Adapter Reset**
```batch
scripts/reset-network.bat
```
- Reset TCP/IP stack
- Clear DNS cache and settings
- Reset Windows Firewall rules
- Restore network adapter configurations

#### 6. **Windows Update Reset**
```batch
scripts/reset-windows-update.bat
```
- Clear Windows Update cache
- Reset update agent components
- Restore automatic update settings
- Clear failed update history

### 🔐 Security & Privacy

#### 7. **User Account Control (UAC) Reset**
```batch
scripts/reset-uac.bat
```
- Reset UAC to default level
- Clear UAC policy overrides
- Restore admin approval mode
- Reset elevation prompts

#### 8. **Privacy Settings Reset**
```batch
scripts/reset-privacy.bat
```
- Reset app permissions
- Clear location history
- Reset microphone/camera access
- Restore default telemetry settings

#### 9. **Windows Defender Reset**
```batch
scripts/reset-defender.bat
```
- Reset Windows Defender settings
- Clear quarantine and exclusions
- Restore real-time protection
- Reset firewall configurations

### 🔍 Search & Interface

#### 10. **Windows Search Reset**
```batch
scripts/reset-search.bat
```
- Rebuild search index
- Reset search options
- Clear search history
- Restore default search locations

#### 11. **Start Menu & Taskbar Reset**
```batch
scripts/reset-startmenu.bat
```
- Reset Start Menu layout
- Clear pinned items
- Restore default taskbar settings
- Reset notification area icons

#### 12. **Windows Shell Reset**
```batch
scripts/reset-shell.bat
```
- Reset Windows Explorer settings
- Clear folder view preferences
- Restore default shell associations
- Reset context menu items

### 📁 File Management

#### 13. **File Associations Reset**
```batch
scripts/reset-file-associations.bat
```
- Reset default programs
- Clear custom file type associations
- Restore Windows default handlers
- Reset protocol associations

#### 14. **Fonts & Text Settings Reset**
```batch
scripts/reset-fonts.bat
```
- Reset system fonts to default
- Clear custom font installations
- Restore text scaling settings
- Reset ClearType configuration

### ⚡ Performance & Power

#### 15. **Power Management Reset**
```batch
scripts/reset-power.bat
```
- Reset power plans to default
- Clear custom power settings
- Restore sleep/hibernate options
- Reset display timeout settings

#### 16. **Performance Counters Reset**
```batch
scripts/reset-performance.bat
```
- Rebuild performance counter registry
- Reset performance monitoring
- Clear corrupted counter data
- Restore system monitoring

### 🌐 Applications & Store

#### 17. **Internet Explorer/Edge Reset**
```batch
scripts/reset-browser.bat
```
- Clear browsing data
- Reset homepage and search engine
- Remove extensions and add-ons
- Restore default security settings

#### 18. **Windows Store Reset**
```batch
scripts/reset-store.bat
```
- Clear Microsoft Store cache
- Reset store preferences
- Restore default store settings
- Clear download history

### ⌨️ Input & Accessibility

#### 19. **Mouse & Keyboard Reset**
```batch
scripts/reset-input-devices.bat
```
- Reset mouse sensitivity and settings
- Clear custom keyboard shortcuts
- Restore default pointer schemes
- Reset accessibility options

### 🛠️ System Components

#### 20. **Windows Features Reset**
```batch
scripts/reset-features.bat
```
- Reset optional Windows features
- Clear custom feature installations
- Restore default component states
- Reset Windows capabilities

#### 21. **System Environment Reset**
```batch
scripts/reset-environment.bat
```
- Clear custom environment variables
- Reset PATH modifications
- Restore default system variables
- Clear user-specific settings

#### 22. **Registry Cleanup & Reset**
```batch
scripts/reset-registry.bat
```
- Reset specific registry keys
- Clear orphaned entries
- Restore default registry values
- Backup before modifications

## 🎛️ Implementation Features

- **💾 Backup Creation**: Each script creates backups before making changes
- **🎯 Selective Reset**: Individual script execution or batch processing
- **🛡️ Safety Checks**: Verification prompts and rollback options
- **📋 Logging**: Detailed operation logs for troubleshooting
- **🖥️ GUI Interface**: Optional graphical interface for non-technical users
- **⌨️ Command Line Support**: Full CLI functionality for automation

## 📋 Prerequisites

### System Requirements
- **OS**: Windows 10/11 (64-bit recommended)
- **Privileges**: Administrator rights required
- **PowerShell**: Version 5.0 or higher
- **Framework**: .NET Framework 4.7.2+

### Before You Begin
- Create a system restore point
- Close all unnecessary applications
- Ensure you have administrator privileges
- Review which settings you want to reset

## 🚀 Quick Start

### Option 1: Individual Script Execution
```cmd
# Run as Administrator
cd ReSet/scripts
reset-language-settings.bat
```

### Option 2: Batch Processing
```cmd
# Run multiple scripts
batch-reset.bat --scripts "language,datetime,display"
```

### Option 3: Interactive Menu
```cmd
# Launch interactive interface
batch-reset.bat
```

## 📁 Project Structure

```
ReSet/
├── 📁 scripts/
│   ├── utils.bat
│   ├── reset-language-settings.bat
│   ├── reset-datetime.bat
│   ├── reset-display.bat
│   ├── reset-audio.bat
│   ├── reset-network.bat
│   ├── reset-windows-update.bat
│   ├── reset-uac.bat
│   ├── reset-search.bat
│   ├── reset-startmenu.bat
│   ├── reset-file-associations.bat
│   ├── reset-privacy.bat
│   ├── reset-power.bat
│   ├── reset-defender.bat
│   ├── reset-browser.bat
│   ├── reset-store.bat
│   ├── reset-fonts.bat
│   ├── reset-input-devices.bat
│   ├── reset-features.bat
│   ├── reset-environment.bat
│   ├── reset-registry.bat
│   ├── reset-shell.bat
│   └── reset-performance.bat
├── 📁 gui/
├── 📁 logs/
├── 📁 backups/
├── 📁 docs/
├── batch-reset.bat
├── install.bat
├── restore-backup.bat
└── README.md
```

## 🔧 Usage Examples

### Reset Language Settings
```cmd
# Basic reset
scripts\reset-language-settings.bat

# With backup verification
scripts\reset-language-settings.bat --verify-backup

# Silent mode (no prompts)
scripts\reset-language-settings.bat --silent
```

### Reset Multiple Categories
```cmd
# Reset display and audio together
batch-reset.bat --categories "display,audio"

# Reset all network-related settings
batch-reset.bat --categories "network,browser,store"
```

### Advanced Options
```cmd
# Create restore point before reset
batch-reset.bat --create-restore-point --categories "all"

# Custom backup location
scripts\reset-display.bat --backup-path "D:\ReSet-Backups"
```

## ⚠️ Important Warnings

- **🔴 Administrator Rights**: All scripts require administrator privileges
- **💾 Backup First**: Always create backups before running scripts
- **🔄 System Restart**: Some resets may require system restart
- **⚡ Data Loss**: Some scripts may clear user preferences and customizations
- **🧪 Test Environment**: Test scripts in a safe environment first

## 📝 Logging

All operations are logged to:
```
logs/reset-operations-YYYY-MM-DD.log
```

Log levels:
- **INFO**: General operation information
- **WARN**: Warnings about potential issues
- **ERROR**: Script execution errors
- **SUCCESS**: Successful operation completion

## 🔄 Rollback Options

### Automatic Backups
- Registry settings backed up before changes
- Configuration files copied to backup directory
- Restore points created for system-level changes

### Manual Rollback
```cmd
# Restore from specific backup
restore-backup.bat --date "2024-01-15" --category "display"

# Restore all settings from backup
restore-backup.bat --restore-all --date "2024-01-15"
```

## 🚀 Installation

### Quick Install
```cmd
# Download and run installer
install.bat
```

### Manual Setup
1. Extract ReSet toolkit to desired location
2. Run `install.bat` as Administrator
3. Follow the installation prompts
4. Use desktop shortcut or Start Menu entries

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Bug Reports & Feature Requests

Please use GitHub Issues to report bugs or request new features:
- [Report a Bug](https://github.com/jomardyan/ReSet/issues/new?template=bug_report.md)
- [Request a Feature](https://github.com/jomardyan/ReSet/issues/new?template=feature_request.md)

## 📞 Support

- **Documentation**: [Wiki](https://github.com/jomardyan/ReSet/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/jomardyan/ReSet/discussions)
- **Issues**: [GitHub Issues](https://github.com/jomardyan/ReSet/issues)

## 🔗 Related Projects

- [win-regional-reset](https://github.com/jomardyan/win-regional-reset) - Specialized regional settings reset
- [System-Extract](https://github.com/jomardyan/System-Extract) - System information extraction tools
- [script-runner-ide](https://github.com/jomardyan/script-runner-ide) - Script development environment

---

**⭐ Star this repository if you find it helpful!**

Made with ❤️ by [jomardyan](https://github.com/jomardyan)

> A comprehensive collection of Windows configuration reset scripts for system administrators, IT professionals, and power users.

## 🎯 Overview

**ReSet** is a powerful Windows settings reset toolkit designed to quickly restore various Windows configurations to their default states. This utility collection addresses common scenarios where users need to reset specific system settings without performing a full system restore or reinstallation.

## 🚀 Purpose & Use Cases

- **🔧 System Administration**: IT professionals managing multiple Windows machines
- **🛠️ Troubleshooting**: Resolving configuration conflicts and corrupted settings
- **✨ Clean Slate Setup**: Preparing systems for new users or deployments
- **🔒 Privacy Reset**: Clearing personalized settings and returning to defaults
- **⚡ Performance Optimization**: Resetting settings that may impact system performance

## 👥 Target Audience

- System Administrators
- IT Support Technicians
- Power Users
- Developers setting up clean environments
- Users experiencing configuration-related issues

## 📦 Reset Scripts Collection

### 🌐 Language & Regional Settings

#### 1. **Language & Regional Settings Reset**
```batch
scripts/reset-language-settings.bat
```
- Reset system locale to default
- Clear custom date/time formats
- Reset number and currency formats
- Restore default keyboard layouts

#### 2. **Time Zone & Date Reset**
```batch
scripts/reset-datetime.bat
```
- Reset to automatic time zone detection
- Clear custom time servers
- Restore default date/time display formats
- Reset calendar preferences

### 🖥️ Display & Audio

#### 3. **Display Settings Reset**
```batch
scripts/reset-display.bat
```
- Reset screen resolution to recommended
- Clear custom DPI scaling
- Reset monitor arrangements
- Restore default color profiles

#### 4. **Audio Settings Reset**
```batch
scripts/reset-audio.bat
```
- Reset default playback/recording devices
- Clear custom audio enhancements
- Reset volume levels to default
- Restore system sounds scheme

### 🌐 Network & Connectivity

#### 5. **Network Adapter Reset**
```batch
scripts/reset-network.bat
```
- Reset TCP/IP stack
- Clear DNS cache and settings
- Reset Windows Firewall rules
- Restore network adapter configurations

#### 6. **Windows Update Reset**
```batch
scripts/reset-windows-update.bat
```
- Clear Windows Update cache
- Reset update agent components
- Restore automatic update settings
- Clear failed update history

### 🔐 Security & Privacy

#### 7. **User Account Control (UAC) Reset**
```batch
scripts/reset-uac.bat
```
- Reset UAC to default level
- Clear UAC policy overrides
- Restore admin approval mode
- Reset elevation prompts

#### 8. **Privacy Settings Reset**
```batch
scripts/reset-privacy.bat
```
- Reset app permissions
- Clear location history
- Reset microphone/camera access
- Restore default telemetry settings

#### 9. **Windows Defender Reset**
```batch
scripts/reset-defender.bat
```
- Reset Windows Defender settings
- Clear quarantine and exclusions
- Restore real-time protection
- Reset firewall configurations

### 🔍 Search & Interface

#### 10. **Windows Search Reset**
```batch
scripts/reset-search.bat
```
- Rebuild search index
- Reset search options
- Clear search history
- Restore default search locations

#### 11. **Start Menu & Taskbar Reset**
```batch
scripts/reset-startmenu.bat
```
- Reset Start Menu layout
- Clear pinned items
- Restore default taskbar settings
- Reset notification area icons

#### 12. **Windows Shell Reset**
```batch
scripts/reset-shell.bat
```
- Reset Windows Explorer settings
- Clear folder view preferences
- Restore default shell associations
- Reset context menu items

### 📁 File Management

#### 13. **File Associations Reset**
```batch
scripts/reset-file-associations.bat
```
- Reset default programs
- Clear custom file type associations
- Restore Windows default handlers
- Reset protocol associations

#### 14. **Fonts & Text Settings Reset**
```batch
scripts/reset-fonts.bat
```
- Reset system fonts to default
- Clear custom font installations
- Restore text scaling settings
- Reset ClearType configuration

### ⚡ Performance & Power

#### 15. **Power Management Reset**
```batch
scripts/reset-power.bat
```
- Reset power plans to default
- Clear custom power settings
- Restore sleep/hibernate options
- Reset display timeout settings

#### 16. **Performance Counters Reset**
```batch
scripts/reset-performance.bat
```
- Rebuild performance counter registry
- Reset performance monitoring
- Clear corrupted counter data
- Restore system monitoring

### 🌐 Applications & Store

#### 17. **Internet Explorer/Edge Reset**
```batch
scripts/reset-browser.bat
```
- Clear browsing data
- Reset homepage and search engine
- Remove extensions and add-ons
- Restore default security settings

#### 18. **Windows Store Reset**
```batch
scripts/reset-store.bat
```
- Clear Microsoft Store cache
- Reset store preferences
- Restore default store settings
- Clear download history

### ⌨️ Input & Accessibility

#### 19. **Mouse & Keyboard Reset**
```batch
scripts/reset-input-devices.bat
```
- Reset mouse sensitivity and settings
- Clear custom keyboard shortcuts
- Restore default pointer schemes
- Reset accessibility options

### 🛠️ System Components

#### 20. **Windows Features Reset**
```batch
scripts/reset-features.bat
```
- Reset optional Windows features
- Clear custom feature installations
- Restore default component states
- Reset Windows capabilities

#### 21. **System Environment Reset**
```batch
scripts/reset-environment.bat
```
- Clear custom environment variables
- Reset PATH modifications
- Restore default system variables
- Clear user-specific settings

#### 22. **Registry Cleanup & Reset**
```batch
scripts/reset-registry.bat
```
- Reset specific registry keys
- Clear orphaned entries
- Restore default registry values
- Backup before modifications

## 🎛️ Implementation Features

- **💾 Backup Creation**: Each script creates backups before making changes
- **🎯 Selective Reset**: Individual script execution or batch processing
- **🛡️ Safety Checks**: Verification prompts and rollback options
- **📋 Logging**: Detailed operation logs for troubleshooting
- **🖥️ GUI Interface**: Optional graphical interface for non-technical users
- **⌨️ Command Line Support**: Full CLI functionality for automation

## 📋 Prerequisites

### System Requirements
- **OS**: Windows 10/11 (64-bit recommended)
- **Privileges**: Administrator rights required
- **PowerShell**: Version 5.0 or higher
- **Framework**: .NET Framework 4.7.2+

### Before You Begin
- Create a system restore point
- Close all unnecessary applications
- Ensure you have administrator privileges
- Review which settings you want to reset

## 🚀 Quick Start

### Option 1: Individual Script Execution
```cmd
# Run as Administrator
cd ReSet/scripts
reset-language-settings.bat
```

### Option 2: Batch Processing
```cmd
# Run multiple scripts
batch-reset.bat --scripts "language,datetime,display"
```

### Option 3: GUI Interface
```cmd
# Launch graphical interface
reset-toolkit-gui.exe
```

## 📁 Project Structure

```
ReSet/
├── 📁 scripts/
│   ├── utils.bat
│   ├── reset-language-settings.bat
│   ├── reset-datetime.bat
│   ├── reset-display.bat
│   ├── reset-audio.bat
│   ├── reset-network.bat
│   ├── reset-windows-update.bat
│   ├── reset-uac.bat
│   ├── reset-search.bat
│   ├── reset-startmenu.bat
│   ├── reset-file-associations.bat
│   ├── reset-privacy.bat
│   ├── reset-power.bat
│   ├── reset-defender.bat
│   ├── reset-browser.bat
│   ├── reset-store.bat
│   ├── reset-fonts.bat
│   ├── reset-input-devices.bat
│   ├── reset-features.bat
│   ├── reset-environment.bat
│   ├── reset-registry.bat
│   ├── reset-shell.bat
│   └── reset-performance.bat
├── 📁 gui/
├── 📁 logs/
├── 📁 backups/
├── 📁 docs/
├── batch-reset.bat
├── install.bat
├── restore-backup.bat
└── README.md
```

## 🔧 Usage Examples

### Reset Language Settings
```cmd
# Basic reset
scripts\reset-language-settings.bat

# With backup verification
scripts\reset-language-settings.bat --verify-backup

# Silent mode (no prompts)
scripts\reset-language-settings.bat --silent
```

### Reset Multiple Categories
```cmd
# Reset display and audio together
batch-reset.bat --categories "display,audio"

# Reset all network-related settings
batch-reset.bat --categories "network,browser,store"
```

### Advanced Options
```cmd
# Create restore point before reset
batch-reset.bat --create-restore-point --categories "all"

# Custom backup location
scripts\reset-display.bat --backup-path "D:\ReSet-Backups"
```

## ⚠️ Important Warnings

- **🔴 Administrator Rights**: All scripts require administrator privileges
- **💾 Backup First**: Always create backups before running scripts
- **🔄 System Restart**: Some resets may require system restart
- **⚡ Data Loss**: Some scripts may clear user preferences and customizations
- **🧪 Test Environment**: Test scripts in a safe environment first

## 📝 Logging

All operations are logged to:
```
logs/reset-operations-YYYY-MM-DD.log
```

Log levels:
- **INFO**: General operation information
- **WARN**: Warnings about potential issues
- **ERROR**: Script execution errors
- **SUCCESS**: Successful operation completion

## 🔄 Rollback Options

### Automatic Backups
- Registry settings backed up before changes
- Configuration files copied to backup directory
- Restore points created for system-level changes

### Manual Rollback
```cmd
# Restore from specific backup
restore-backup.bat --date "2024-01-15" --category "display"

# Restore all settings from backup
restore-backup.bat --restore-all --date "2024-01-15"
```

## 🚀 Installation

### Quick Install
```cmd
# Download and run installer
install.bat
```

### Manual Setup
1. Extract ReSet toolkit to desired location
2. Run `install.bat` as Administrator
3. Follow the installation prompts
4. Use desktop shortcut or Start Menu entries

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Bug Reports & Feature Requests

Please use GitHub Issues to report bugs or request new features:
- [Report a Bug](https://github.com/jomardyan/ReSet/issues/new?template=bug_report.md)
- [Request a Feature](https://github.com/jomardyan/ReSet/issues/new?template=feature_request.md)

## 📞 Support

- **Documentation**: [Wiki](https://github.com/jomardyan/ReSet/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/jomardyan/ReSet/discussions)
- **Issues**: [GitHub Issues](https://github.com/jomardyan/ReSet/issues)

## 🔗 Related Projects

- [win-regional-reset](https://github.com/jomardyan/win-regional-reset) - Specialized regional settings reset
- [System-Extract](https://github.com/jomardyan/System-Extract) - System information extraction tools
- [script-runner-ide](https://github.com/jomardyan/script-runner-ide) - Script development environment

---

**⭐ Star this repository if you find it helpful!**

Made with ❤️ by [jomardyan](https://github.com/jomardyan)
