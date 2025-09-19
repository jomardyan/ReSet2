# Quick Deployment Guide - ReSet Toolkit GPO Integration

## 🚀 Quick Start (5 Minutes)

### Prerequisites Checklist
- [ ] Domain Administrator privileges
- [ ] Group Policy Management Console installed
- [ ] PowerShell 5.0+ on target computers
- [ ] 100MB free space on SYSVOL

### Step 1: Install Administrative Templates (2 minutes)

```powershell
# Copy ADMX files to Central Store
$domain = $env:USERDNSDOMAIN
$centralStore = "\\$domain\SYSVOL\$domain\Policies\PolicyDefinitions"

# Copy template files
Copy-Item "gpo-templates\ReSetToolkit.admx" "$centralStore\" -Force
Copy-Item "gpo-templates\en-US\ReSetToolkit.adml" "$centralStore\en-US\" -Force

Write-Host "✅ Administrative templates installed" -ForegroundColor Green
```

### Step 2: Deploy Toolkit to SYSVOL (1 minute)

```powershell
# Copy toolkit to SYSVOL
$sysvolScripts = "\\$domain\SYSVOL\$domain\scripts\ReSetToolkit"
Copy-Item -Path "." -Destination $sysvolScripts -Recurse -Force -Exclude @("*.git*", "*.md", "docs")

Write-Host "✅ Toolkit copied to SYSVOL" -ForegroundColor Green
```

### Step 3: Create and Configure GPO (2 minutes)

```powershell
# Create GPO
$gpoName = "ReSet Toolkit - Enterprise Policy"
New-GPO -Name $gpoName -Domain $domain

# Import policy settings
Import-Module "$PWD\scripts\ReSetUtils.psm1" -Force
.\scripts\GPO-Deployment.ps1 -PolicySettings @{
    Enabled = $true
    BackupRequired = $true
    AuditMode = $true
    LogLevel = "INFO"
    MaintenanceWindow = "22-06"
} -Scope Computer

Write-Host "✅ GPO created and configured" -ForegroundColor Green
```

## 📋 Configuration Profiles

### 🔒 Secure (Recommended for Production)
```powershell
$secureConfig = @{
    Enabled = $true
    RequireApproval = $true
    MaintenanceWindow = "22-06"
    BackupRequired = $true
    MaxBackupDays = 180
    AuditMode = $true
    LogLevel = "INFO"
    AllowRemoteExecution = $false
}
```

### 🛠️ Development Environment
```powershell
$devConfig = @{
    Enabled = $true
    RequireApproval = $false
    BackupRequired = $true
    MaxBackupDays = 30
    AuditMode = $false
    LogLevel = "DEBUG"
    AllowRemoteExecution = $true
}
```

### 🏢 Standard Enterprise
```powershell
$standardConfig = @{
    Enabled = $true
    RequireApproval = $false
    MaintenanceWindow = ""
    BackupRequired = $true
    MaxBackupDays = 90
    AuditMode = $true
    LogLevel = "INFO"
    AllowRemoteExecution = $false
}
```

## 🎯 Deployment Methods

### Method A: GPO Computer Startup Script (Recommended)

1. **Open Group Policy Management Console**
2. **Edit your GPO**
3. **Navigate to**: Computer Configuration > Policies > Windows Settings > Scripts > Startup
4. **Add Script**: 
   - Script Name: `PowerShell.exe`
   - Script Parameters: `-ExecutionPolicy Bypass -File "\\domain.com\SYSVOL\domain.com\scripts\ReSetToolkit\Enterprise-Deployment.ps1" -InstallationType Silent -ConfigurationProfile Secure`

### Method B: Software Installation via MSI

```powershell
# Generate MSI package
.\Enterprise-Deployment.ps1 -InstallationType MSI -ConfigurationProfile Standard

# Deploy via GPO Software Installation
# Computer Configuration > Policies > Software Settings > Software Installation
```

### Method C: Manual with Centralized Policy

```powershell
# Install locally on each computer
.\Install.ps1 -Silent

# Apply GPO configuration
gpupdate /force
```

## 🔧 Common Policy Settings

### Enable/Disable Toolkit
```
Computer Configuration > Policies > Administrative Templates > System > Windows Reset Toolkit
Setting: Enable ReSet Toolkit
Value: Enabled/Disabled
```

### Set Maintenance Window
```
Setting: Maintenance Window
Value: 22-06 (10 PM to 6 AM)
Format: HH-HH (24-hour format)
```

### Require Approval for Operations
```
Setting: Require Administrative Approval
Value: Enabled
Effect: Operations require approval file in config directory
```

### Disable Specific Operations
```
Setting: Disabled Operations
Values: (one per line)
- Reset
- Backup  
- Restore
- Cleanup
- reset-network
- reset-display
```

### Enable Audit Logging
```
Setting: Enable Audit Mode
Value: Enabled
Effect: Comprehensive logging to Windows Event Log
```

## 📊 Verification Commands

### Check Policy Application
```powershell
# Force policy refresh
gpupdate /force

# Verify policy settings
Get-ItemProperty "HKLM:\SOFTWARE\Policies\ReSetToolkit" | Format-List

# Test compliance
Import-Module "C:\Program Files\ReSetToolkit\scripts\ReSetUtils.psm1"
Test-GroupPolicyCompliance -OperationType "Reset"
```

### Verify Installation
```powershell
# Check installation
Test-Path "C:\Program Files\ReSetToolkit\Reset-Manager.ps1"

# Test main script
& "C:\Program Files\ReSetToolkit\Reset-Manager.ps1" -ListScripts

# Check Event Log source
Get-EventLog -LogName Application -Source "ReSetToolkit" -Newest 5
```

## ⚡ PowerShell One-Liners

### Deploy Secure Configuration
```powershell
.\scripts\GPO-Deployment.ps1 -PolicySettings @{Enabled=$true;RequireApproval=$true;AuditMode=$true;BackupRequired=$true} -Scope Computer -Force
```

### Quick Status Check
```powershell
Get-PolicyStatus | Select-Object Computer,PolicyConfiguration,ComplianceTests | ConvertTo-Json -Depth 3
```

### Force Policy Refresh on All Computers
```powershell
Get-ADComputer -Filter * | ForEach-Object { Invoke-Command -ComputerName $_.Name -ScriptBlock { gpupdate /force } -ErrorAction SilentlyContinue }
```

### Bulk Deploy to OU
```powershell
$targetOU = "OU=Workstations,DC=company,DC=com"
Get-ADComputer -SearchBase $targetOU -Filter * | ForEach-Object {
    Invoke-Command -ComputerName $_.Name -ScriptBlock {
        & "\\domain.com\SYSVOL\domain.com\scripts\ReSetToolkit\Enterprise-Deployment.ps1" -InstallationType Silent -ConfigurationProfile Standard
    }
}
```

## 🔍 Troubleshooting Quick Fixes

### Policy Not Applied
```powershell
# Check GPO links
Get-GPInheritance -Target "OU=Computers,DC=domain,DC=com"

# Verify policy precedence
gpresult /r /scope:computer
```

### Administrative Templates Missing
```powershell
# Verify ADMX files
$centralStore = "\\$env:USERDNSDOMAIN\SYSVOL\$env:USERDNSDOMAIN\Policies\PolicyDefinitions"
Test-Path "$centralStore\ReSetToolkit.admx"
Test-Path "$centralStore\en-US\ReSetToolkit.adml"
```

### Operations Blocked
```powershell
# Check current restrictions
Get-ItemProperty "HKLM:\SOFTWARE\Policies\ReSetToolkit" -Name "DisabledOperations" -ErrorAction SilentlyContinue

# Test maintenance window
Test-MaintenanceWindow
```

### Audit Logging Issues
```powershell
# Create Event Log source if missing
New-EventLog -LogName Application -Source "ReSetToolkit"

# Test audit logging
Write-GroupPolicyAuditLog -OperationType "Test" -OperationName "Troubleshooting" -Status "Started"
```

## 📈 Monitoring and Maintenance

### Daily Health Check
```powershell
# Create scheduled task for daily compliance check
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\Daily-Compliance-Check.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "08:00AM"
Register-ScheduledTask -TaskName "ReSet Toolkit Daily Check" -Action $action -Trigger $trigger -User "SYSTEM"
```

### Weekly Reporting
```powershell
# Generate weekly compliance report
$computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
$report = foreach ($computer in $computers) {
    try {
        Invoke-Command -ComputerName $computer -ScriptBlock {
            Import-Module "C:\Program Files\ReSetToolkit\scripts\ReSetUtils.psm1" -ErrorAction Stop
            Get-PolicyStatus
        } -ErrorAction Stop
    } catch {
        [PSCustomObject]@{Computer=$computer; Status="Error"; Message=$_.Exception.Message}
    }
}
$report | Export-Csv "C:\Reports\ReSetToolkit-Weekly-$(Get-Date -Format 'yyyy-MM-dd').csv"
```

## 🆘 Emergency Procedures

### Disable Toolkit Domain-Wide
```powershell
# Emergency disable via registry
Get-ADComputer -Filter * | ForEach-Object {
    Invoke-Command -ComputerName $_.Name -ScriptBlock {
        Set-ItemProperty "HKLM:\SOFTWARE\Policies\ReSetToolkit" -Name "Enabled" -Value 0 -Force
    } -ErrorAction SilentlyContinue
}
```

### Remove All Policies
```powershell
# Remove GPO policies
Remove-ReSetPolicy -Scope Both -Force

# Clean registry on all computers
Get-ADComputer -Filter * | ForEach-Object {
    Invoke-Command -ComputerName $_.Name -ScriptBlock {
        Remove-Item "HKLM:\SOFTWARE\Policies\ReSetToolkit" -Recurse -Force -ErrorAction SilentlyContinue
    }
}
```

## 📞 Support Resources

- **Full Documentation**: [docs/gpo-integration/README.md](README.md)
- **API Reference**: [docs/api/README.md](../api/README.md)
- **GitHub Issues**: [Report Problems](https://github.com/jomardyan/ReSet2/issues)
- **Sample Scripts**: [examples/](examples/)

---

*For detailed explanations and advanced scenarios, see the complete [GPO Integration Guide](README.md)*