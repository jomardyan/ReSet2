# Group Policy Integration Guide for ReSet Toolkit 2.0

## Overview

The ReSet Toolkit 2.0 includes comprehensive Group Policy (GPO) integration designed for enterprise environments. This guide covers deployment, configuration, and management of the toolkit through Active Directory Group Policy.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Installation Methods](#installation-methods)
4. [Group Policy Configuration](#group-policy-configuration)
5. [Deployment Scenarios](#deployment-scenarios)
6. [Security and Compliance](#security-and-compliance)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

## Architecture Overview

### GPO Integration Components

```
ReSet Toolkit GPO Architecture
├── Administrative Templates (ADMX/ADML)
│   ├── ReSetToolkit.admx (Policy definitions)
│   └── en-US/ReSetToolkit.adml (English resources)
├── Registry-Based Configuration
│   ├── HKLM:\SOFTWARE\Policies\ReSetToolkit (Computer policies)
│   └── HKCU:\SOFTWARE\Policies\ReSetToolkit (User policies)
├── PowerShell Integration
│   ├── Group Policy compliance checking
│   ├── Centralized logging and auditing
│   └── Silent execution capabilities
└── Enterprise Deployment Tools
    ├── Enterprise-Deployment.ps1
    ├── GPO-Deployment.ps1
    └── MSI package generation
```

### Policy Hierarchy

1. **Computer Policies** (Highest precedence)
   - Operations control (enable/disable)
   - Security settings (approval, maintenance windows)
   - Backup and retention policies
   - Logging and auditing configuration

2. **User Policies** (Lower precedence)
   - Notification levels
   - User override permissions
   - Interface customization

3. **Local Configuration** (Lowest precedence)
   - Default toolkit settings
   - Fallback configuration

## Prerequisites

### Domain Environment
- Active Directory domain with Group Policy infrastructure
- Windows Server 2012 R2 or higher (Domain Controllers)
- Group Policy Management Console (GPMC)
- PowerShell 5.0 or higher on target computers

### Permissions Required
- **Domain Admin** or **Group Policy Creator Owners** (for GPO creation)
- **Enterprise Admin** (for schema modifications, if needed)
- **Local Administrator** (on target computers for installation)

### Supported Windows Versions
- Windows 10 (all versions)
- Windows 11 (all versions)
- Windows Server 2016 and higher

## Installation Methods

### Method 1: Silent Installation via Group Policy

1. **Copy Installation Files to SYSVOL**
   ```powershell
   # Copy toolkit to domain SYSVOL
   $sysvolPath = "\\domain.com\SYSVOL\domain.com\scripts\ReSetToolkit"
   Copy-Item -Path "C:\ReSetToolkit" -Destination $sysvolPath -Recurse -Force
   ```

2. **Create GPO for Installation**
   ```powershell
   # Run on domain controller or system with GPMC
   New-GPO -Name "ReSet Toolkit Installation" -Domain "domain.com"
   ```

3. **Configure Computer Startup Script**
   - Add startup script: `Enterprise-Deployment.ps1 -InstallationType Silent -ConfigurationProfile Secure`
   - Link GPO to target OUs

### Method 2: Software Installation via GPO

1. **Create MSI Package**
   ```powershell
   .\Enterprise-Deployment.ps1 -InstallationType MSI -ConfigurationProfile Default
   ```

2. **Deploy via Software Installation**
   - Computer Configuration > Policies > Software Settings > Software Installation
   - Add MSI package from network share
   - Configure deployment options (assigned/published)

### Method 3: Manual Deployment with Centralized Configuration

1. **Install Locally**
   ```powershell
   .\Install.ps1 -Silent -InstallPath "C:\Program Files\ReSetToolkit"
   ```

2. **Apply GPO Configuration**
   ```powershell
   .\scripts\GPO-Deployment.ps1 -PolicySettings @{
       Enabled = $true
       AuditMode = $true
       BackupRequired = $true
   }
   ```

## Group Policy Configuration

### Installing Administrative Templates

1. **Copy ADMX Files**
   ```powershell
   # Copy to PolicyDefinitions folder
   $policyPath = "$env:SYSTEMROOT\PolicyDefinitions"
   Copy-Item "gpo-templates\ReSetToolkit.admx" "$policyPath\" -Force
   Copy-Item "gpo-templates\en-US\ReSetToolkit.adml" "$policyPath\en-US\" -Force
   ```

2. **For Central Store (Recommended)**
   ```powershell
   # Copy to domain central store
   $centralStore = "\\domain.com\SYSVOL\domain.com\Policies\PolicyDefinitions"
   Copy-Item "gpo-templates\ReSetToolkit.admx" "$centralStore\" -Force
   Copy-Item "gpo-templates\en-US\ReSetToolkit.adml" "$centralStore\en-US\" -Force
   ```

### Policy Categories

#### 1. Operations Control
- **Enable ReSet Toolkit**: Master switch for all operations
- **Disabled Operations**: Specify which operation types to block
- **Enable Silent Mode**: Allow unattended execution
- **Execution Timeout**: Maximum time for operations (1-120 minutes)

#### 2. Security Settings
- **Require Administrative Approval**: Mandate approval for operations
- **Maintenance Window**: Restrict operations to specific hours (HH-HH format)
- **Allow Remote Execution**: Enable remote management capabilities
- **Allow User Override**: Permit users to bypass certain restrictions

#### 3. Backup and Recovery
- **Require Backup Before Operations**: Force backup creation
- **Automatic Backup**: Enable automatic backup without user intervention
- **Maximum Backup Retention Days**: Set retention period (1-365 days)

#### 4. Logging and Auditing
- **Logging Level**: Control log verbosity (Error/Warning/Info/Debug)
- **Enable Audit Mode**: Comprehensive compliance logging
- **Enable Windows Event Log Integration**: SIEM integration support

### Configuration Examples

#### Secure Enterprise Environment
```
Enable ReSet Toolkit: Enabled
Require Administrative Approval: Enabled
Maintenance Window: 22-06 (10 PM to 6 AM)
Require Backup Before Operations: Enabled
Maximum Backup Retention Days: 180
Logging Level: Info
Enable Audit Mode: Enabled
Allow Remote Execution: Disabled
```

#### Development Environment
```
Enable ReSet Toolkit: Enabled
Require Administrative Approval: Disabled
Maintenance Window: Not Configured
Require Backup Before Operations: Enabled
Maximum Backup Retention Days: 30
Logging Level: Debug
Enable Audit Mode: Disabled
Allow Remote Execution: Enabled
```

#### Minimal/Restricted Environment
```
Enable ReSet Toolkit: Enabled
Disabled Operations: Restore,Cleanup
Require Administrative Approval: Enabled
Maintenance Window: 02-04 (2 AM to 4 AM)
Require Backup Before Operations: Enabled
Maximum Backup Retention Days: 90
Logging Level: Warning
Enable Audit Mode: Enabled
Allow Remote Execution: Disabled
```

## Deployment Scenarios

### Scenario 1: Domain-Wide Deployment

**Objective**: Deploy toolkit to all domain computers with unified configuration

**Steps**:
1. Create domain-level GPO: "ReSet Toolkit - Domain Policy"
2. Configure computer policies for enterprise settings
3. Link GPO to domain root
4. Test on pilot OU before full deployment

**GPO Settings**:
```powershell
Deploy-ReSetToolkitPolicy -PolicySettings @{
    Enabled = $true
    RequireApproval = $true
    MaintenanceWindow = "22-06"
    BackupRequired = $true
    MaxBackupDays = 180
    AuditMode = $true
    LogLevel = "INFO"
    AllowRemoteExecution = $false
} -Scope Computer
```

### Scenario 2: OU-Specific Deployment

**Objective**: Different configurations for different organizational units

**Example Structure**:
- **Servers OU**: Highly restricted, audit mode, long backup retention
- **Workstations OU**: Standard settings, user notifications
- **Development OU**: Relaxed settings, debug logging, remote execution

**Implementation**:
```powershell
# Servers OU
Deploy-ReSetToolkitPolicy -PolicySettings @{
    Enabled = $true
    RequireApproval = $true
    MaintenanceWindow = "02-04"
    BackupRequired = $true
    MaxBackupDays = 365
    AuditMode = $true
    LogLevel = "INFO"
    DisabledOperations = "Cleanup"
} -Scope Computer

# Development OU
Deploy-ReSetToolkitPolicy -PolicySettings @{
    Enabled = $true
    RequireApproval = $false
    BackupRequired = $true
    MaxBackupDays = 30
    AuditMode = $false
    LogLevel = "DEBUG"
    AllowRemoteExecution = $true
} -Scope Computer
```

### Scenario 3: Pilot Deployment

**Objective**: Test deployment on limited set of computers

**Steps**:
1. Create pilot OU: "ReSet Toolkit Pilot"
2. Move test computers to pilot OU
3. Create and link pilot GPO
4. Monitor and validate functionality
5. Expand to production OUs

**Pilot Configuration**:
```powershell
Deploy-ReSetToolkitPolicy -PolicySettings @{
    Enabled = $true
    RequireApproval = $false
    BackupRequired = $true
    MaxBackupDays = 30
    AuditMode = $true
    LogLevel = "DEBUG"
    NotificationLevel = "Verbose"
} -Scope Computer -Force
```

## Security and Compliance

### Audit and Compliance Features

1. **Windows Event Log Integration**
   - Event ID 1001: Operation Started
   - Event ID 1002: Operation Completed
   - Event ID 1003: Operation Failed
   - Event ID 1004: Operation Blocked by Policy

2. **Detailed Audit Logging**
   ```json
   {
     "Timestamp": "2024-01-15 10:30:00",
     "Computer": "WS-001",
     "User": "DOMAIN\\john.doe",
     "OperationType": "Reset",
     "OperationName": "Network Settings Reset",
     "Status": "Completed",
     "Compliance": {
       "Status": "Compliant",
       "PolicySource": "Computer Policy"
     }
   }
   ```

3. **SIEM Integration**
   - JSON-formatted log entries
   - Event Log forwarding support
   - Custom event sources
   - Compliance status tracking

### Security Controls

#### Access Control
- Administrative rights required for all operations
- Group Policy enforcement cannot be bypassed
- Audit trail for all policy changes

#### Data Protection
- Automatic backup creation before destructive operations
- Encrypted backup storage (optional)
- Backup integrity verification
- Configurable retention policies

#### Change Management
- Approval workflows for sensitive operations
- Maintenance window enforcement
- Operation scheduling and throttling
- Rollback capabilities

### Compliance Standards

The toolkit supports compliance with:
- **SOX (Sarbanes-Oxley)**: Financial system change controls
- **HIPAA**: Healthcare system security requirements
- **PCI DSS**: Payment card industry standards
- **ISO 27001**: Information security management
- **NIST**: Cybersecurity framework alignment

## Troubleshooting

### Common Issues

#### 1. Group Policy Not Applied
**Symptoms**: Policies not taking effect on target computers

**Solutions**:
```powershell
# Force Group Policy refresh
gpupdate /force /target:computer

# Check policy application
gpresult /h GPReport.html

# Verify policy registry keys
Get-ItemProperty "HKLM:\SOFTWARE\Policies\ReSetToolkit" -ErrorAction SilentlyContinue
```

#### 2. Administrative Templates Not Visible
**Symptoms**: ReSet Toolkit policies not visible in GPMC

**Solutions**:
```powershell
# Verify ADMX file placement
Test-Path "$env:SYSTEMROOT\PolicyDefinitions\ReSetToolkit.admx"
Test-Path "$env:SYSTEMROOT\PolicyDefinitions\en-US\ReSetToolkit.adml"

# Check central store (if used)
$centralStore = "\\domain.com\SYSVOL\domain.com\Policies\PolicyDefinitions"
Test-Path "$centralStore\ReSetToolkit.admx"
```

#### 3. Operations Blocked by Policy
**Symptoms**: Scripts fail with compliance errors

**Diagnostics**:
```powershell
# Check policy compliance
Test-GroupPolicyCompliance -OperationType "Reset"

# View current policy configuration
Get-GroupPolicyConfiguration | ConvertTo-Json

# Check maintenance window
Test-MaintenanceWindow
```

#### 4. Audit Logging Not Working
**Symptoms**: No audit entries in Event Log

**Solutions**:
```powershell
# Verify Event Log source
Get-EventLog -LogName Application -Source "ReSetToolkit" -Newest 10

# Check audit mode setting
Get-ItemProperty "HKLM:\SOFTWARE\Policies\ReSetToolkit" -Name "AuditMode"

# Test Event Log writing
Write-EventLog -LogName Application -Source "ReSetToolkit" -EventId 1000 -Message "Test"
```

### Diagnostic Commands

```powershell
# Comprehensive policy status
Get-PolicyStatus | ConvertTo-Json -Depth 10

# Test deployment verification
Test-PolicyDeployment -Scope Both

# Validate configuration
Test-PolicyConfiguration -PolicySettings (Get-GroupPolicyConfiguration).ComputerPolicy

# Generate deployment report
Invoke-SystemReport | Out-File "C:\Reports\ReSetToolkit-Status.html"
```

## Best Practices

### Planning and Design

1. **Start with Pilot Deployment**
   - Test on non-critical systems first
   - Validate policy settings in isolated OU
   - Monitor for unexpected behaviors

2. **Use Staging Approach**
   - Development → Testing → Production
   - Incremental rollout by OU
   - Rollback plan for each phase

3. **Document Configuration**
   - Maintain configuration baselines
   - Document policy decisions and rationale
   - Version control for policy changes

### Configuration Management

1. **Centralized Configuration**
   ```powershell
   # Export current configuration
   Export-PolicyConfiguration -ExportPath "C:\Config\ReSetToolkit-Config.json" -Format JSON
   
   # Import to new environment
   Import-PolicyConfiguration -ImportPath "C:\Config\ReSetToolkit-Config.json" -ValidateOnly
   ```

2. **Environment-Specific Settings**
   - Development: Debug logging, relaxed restrictions
   - Testing: Standard settings, audit mode
   - Production: Secure settings, full compliance

3. **Regular Policy Review**
   - Monthly configuration audits
   - Quarterly policy effectiveness review
   - Annual security assessment

### Security Hardening

1. **Principle of Least Privilege**
   - Disable unnecessary operations
   - Implement approval workflows
   - Restrict remote execution

2. **Defense in Depth**
   - Multiple policy layers (computer + user)
   - Backup verification requirements
   - Comprehensive audit logging

3. **Incident Response**
   - Automated alerting for policy violations
   - Rapid rollback procedures
   - Forensic logging capabilities

### Monitoring and Maintenance

1. **Automated Monitoring**
   ```powershell
   # Scheduled task for policy compliance checking
   $taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\Check-ReSetCompliance.ps1"
   $taskTrigger = New-ScheduledTaskTrigger -Daily -At "08:00AM"
   Register-ScheduledTask -TaskName "ReSet Toolkit Compliance Check" -Action $taskAction -Trigger $taskTrigger
   ```

2. **Regular Maintenance**
   - Backup cleanup automation
   - Log rotation and archival
   - Policy configuration updates

3. **Performance Optimization**
   - Monitor operation execution times
   - Optimize maintenance windows
   - Balance security vs. usability

## Advanced Scenarios

### Integration with SCCM

```powershell
# Create SCCM package
.\Enterprise-Deployment.ps1 -InstallationType SCCM -ConfigurationProfile Secure

# Deploy via SCCM application model
New-CMApplication -Name "ReSet Toolkit 2.0" -LocalizedDisplayName "Windows Reset Toolkit"
```

### PowerShell DSC Integration

```powershell
Configuration ReSetToolkitConfig {
    param(
        [string]$ConfigurationProfile = "Default"
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    
    Registry ReSetToolkitEnabled {
        Ensure = "Present"
        Key = "HKLM:\SOFTWARE\Policies\ReSetToolkit"
        ValueName = "Enabled"
        ValueData = 1
        ValueType = "DWord"
    }
    
    # Additional DSC resources...
}
```

### Custom Configuration Server

```powershell
# Set centralized configuration server
Set-ReSetPolicyConfiguration -SettingName "ConfigurationServer" -SettingValue "https://config.company.com/reset-toolkit" -Scope Computer -Force

# Automatic configuration updates
$configUrl = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\ReSetToolkit").ConfigurationServer
if ($configUrl) {
    $remoteConfig = Invoke-RestMethod -Uri "$configUrl/config.json"
    Import-PolicyConfiguration -ImportPath $remoteConfig -Force
}
```

## Support and Resources

### Documentation
- [Installation Guide](../installation/README.md)
- [Configuration Reference](../configuration/README.md)
- [API Documentation](../api/README.md)
- [Troubleshooting Guide](../troubleshooting/README.md)

### Tools and Scripts
- `Enterprise-Deployment.ps1`: Main deployment script
- `GPO-Deployment.ps1`: Group Policy management
- `scripts/ReSetUtils.psm1`: Core utility functions
- `gpo-templates/`: ADMX/ADML files

### Community and Support
- GitHub Repository: [ReSet Toolkit](https://github.com/jomardyan/ReSet2)
- Documentation Wiki: [Enterprise Deployment](https://github.com/jomardyan/ReSet2/wiki)
- Issues and Bug Reports: [GitHub Issues](https://github.com/jomardyan/ReSet2/issues)

---

*This documentation is part of the ReSet Toolkit 2.0 enterprise deployment guide. For the latest updates and additional resources, visit the project repository.*