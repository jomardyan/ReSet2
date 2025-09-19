# GitHub Copilot Instructions for ReSet Toolkit 2.0

This document provides GitHub Copilot with context and guidelines for working with the Windows Reset Toolkit 2.0 project.

## Project Overview

**ReSet Toolkit 2.0** is an enterprise-grade PowerShell-based Windows administration and troubleshooting suite featuring:
- 49+ PowerShell functions across 29 modules
- Active Directory integration and domain management
- Comprehensive backup and restore system
- Performance optimization tools
- Standalone admin utilities

## Architecture & Structure

### Core Components
- **PowerShell 5.0+ Framework**: Modern module-based architecture
- **Central Utility Module**: `scripts/ReSetUtils.psm1` (26 infrastructure functions)
- **Reset Modules**: 28 specialized Windows component reset scripts
- **AD Integration**: 2 modules with 16 Active Directory functions
- **Admin Tools**: 3 standalone utilities (HealthCheck, AD-Tools, SystemCleanup)

### Directory Structure
```
ReSet2/
├── Reset-Manager.ps1              # Main interactive CLI
├── Install.ps1                    # Enhanced installer
├── HealthCheck.ps1               # System health checker
├── AD-Tools.ps1                  # AD troubleshooting
├── SystemCleanup.ps1             # System cleanup utility
├── scripts/                      # Core PowerShell modules
│   ├── ReSetUtils.psm1          # Central utility module
│   ├── reset-active-directory.ps1    # AD management
│   ├── reset-ad-host-cleanup.ps1     # Host AD cleanup
│   ├── reset-system-performance.ps1  # Performance optimization
│   └── reset-*.ps1              # Windows component resets
├── logs/                         # Operation logs
├── backups/                      # Backup storage
└── docs/                         # Documentation
```

## Coding Standards & Patterns

### PowerShell Standards
- **Version**: PowerShell 5.0+ compatibility required
- **Admin Rights**: All operations require `#Requires -RunAsAdministrator`
- **Error Handling**: Use try-catch blocks with proper logging
- **Logging**: Use `Write-ReSetLog` for all operations
- **Validation**: Use `Assert-AdminRights` and parameter validation

### Function Naming Conventions
- **Reset Functions**: `Reset-ComponentName` (e.g., `Reset-NetworkSettings`)
- **Utility Functions**: `Verb-ReSetNoun` (e.g., `New-ReSetBackup`)
- **Internal Functions**: Use approved PowerShell verbs
- **Parameters**: Use proper PowerShell parameter attributes

### Code Structure Template
```powershell
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Brief description of the script purpose
.DESCRIPTION
    Detailed description of functionality
.AUTHOR
    ReSet Toolkit
.VERSION
    2.0.0
.FUNCTIONS
    - List of functions in the script
#>

# Import utility functions
Import-Module "$PSScriptRoot\ReSetUtils.psm1" -Force

function Reset-ComponentName {
    <#
    .SYNOPSIS
        Reset specific Windows component
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $operationName = "Component Reset"
    $backupName = "ComponentBackup"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "Description of changes")) {
                return
            }
        }
        
        # Create backup before changes
        New-ReSetBackup -BackupName $backupName -RegistryPaths @("HKLM:\Path")
        
        Write-ProgressStep "Performing reset operation..."
        # Reset logic here
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
    } catch {
        Write-ReSetLog "Error in reset operation: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}
```

## Key Utility Functions

### Logging & Operations
```powershell
Write-ReSetLog "Message" "INFO|WARN|ERROR|SUCCESS"
Start-ReSetOperation -Name "Operation Name"
Complete-ReSetOperation -Name "Operation Name" -Status "Success|Failed"
```

### Backup & Restore
```powershell
New-ReSetBackup -BackupName "Name" -RegistryPaths @("HKLM:\Path")
Restore-ReSetBackup -BackupName "Name" -Verify
Get-ReSetBackupList | Where-Object {$_.Name -like "Pattern*"}
```

### System Utilities
```powershell
Test-IsAdmin                     # Check admin privileges
Assert-AdminRights              # Enforce admin rights
Confirm-ReSetOperation          # User confirmation
Write-ProgressStep "Step..."    # Progress indication
```

### Registry & Services
```powershell
Set-RegistryValue -Path "HKLM:\Path" -Name "ValueName" -Value $value -Type DWord
Remove-RegistryValue -Path "HKLM:\Path" -Name "ValueName"
Restart-WindowsService -ServiceName "ServiceName"
```

### Advanced Features
```powershell
Get-SystemHealth                # System health assessment
Test-ActiveDirectoryConnectivity # AD connectivity test
Invoke-AdvancedCleanup          # Multi-target cleanup
Invoke-SystemReport             # HTML report generation
```

## Active Directory Integration

### Domain Management Functions
- `Reset-DomainConnectivity` - Repair domain connections
- `Reset-ADCredentials` - Credential cache management
- `Reset-GroupPolicyCache` - GP cache operations
- `Reset-KerberosAuthentication` - Kerberos ticket management

### Host Computer Cleanup Functions
- `Reset-ComputerAccount` - Computer account operations
- `Reset-DomainTrust` - Trust relationship repair
- `Reset-HostADCache` - Host-specific cache cleanup
- `Repair-DomainMembership` - Complete domain repair workflow

### AD Coding Patterns
```powershell
# Check domain membership
$computerSystem = Get-WmiObject -Class Win32_ComputerSystem
if (-not $computerSystem.PartOfDomain) {
    Write-Host "Computer is not domain-joined" -ForegroundColor Yellow
    return
}

# Test AD connectivity
$adStatus = Test-ActiveDirectoryConnectivity
if ($adStatus.Status -ne "Connected") {
    # Handle AD connectivity issues
}
```

## Performance Optimization Patterns

### Performance Profiles
- **Performance**: Maximum speed optimization
- **Balanced**: Performance/power balance
- **PowerSaver**: Energy efficiency focus

### Memory Management
```powershell
# Clear working sets
Get-Process | ForEach-Object {
    try { $_.WorkingSet = $_.MinWorkingSet } catch { }
}

# Optimize page file
$totalRAM = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
if ($totalRAM -ge 8) {
    Set-RegistryValue -Path $memPath -Name "PagingFiles" -Value "C:\pagefile.sys 1024 4096"
}
```

## Error Handling Best Practices

### Standard Error Pattern
```powershell
try {
    # Operation code
    Write-ReSetLog "Operation completed successfully" "SUCCESS"
} catch {
    Write-ReSetLog "Operation failed: $($_.Exception.Message)" "ERROR"
    throw
}
```

### User Confirmation Pattern
```powershell
if (-not $Force) {
    if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "High" -Description "This will reset critical settings")) {
        return
    }
}
```

## Testing & Validation

### Function Testing
- Test with different Windows versions (10/11)
- Verify administrator privilege enforcement
- Test backup and restore operations
- Validate error handling and logging

### Integration Testing
- Test with domain-joined and workgroup computers
- Verify AD operations on domain controllers
- Test performance optimization profiles
- Validate backup system integrity

## Documentation Standards

### Function Documentation
```powershell
<#
.SYNOPSIS
    Brief one-line description
.DESCRIPTION
    Detailed description of functionality and behavior
.PARAMETER ParameterName
    Description of parameter purpose and valid values
.EXAMPLE
    Example usage with explanation
.NOTES
    Additional information, warnings, or requirements
#>
```

### Script Headers
```powershell
<#
.SYNOPSIS
    Script purpose and main functionality
.DESCRIPTION
    Comprehensive description of all functions and capabilities
.AUTHOR
    ReSet Toolkit
.VERSION
    2.0.0
.FUNCTIONS
    - Function1: Description
    - Function2: Description
#>
```

## Security Considerations

### Administrator Enforcement
- All scripts must include `#Requires -RunAsAdministrator`
- Use `Assert-AdminRights` for runtime validation
- Implement proper UAC handling

### Backup Strategy
- Always create backups before destructive operations
- Use comprehensive registry path backups
- Implement restore verification
- Provide rollback capabilities

### Logging & Audit
- Log all operations with timestamps
- Include operation success/failure status
- Log security-sensitive operations
- Maintain audit trails for compliance

## Common Patterns & Examples

### Registry Operations
```powershell
# Safe registry modification
try {
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -Name "SettingName" -Value 1 -Type DWord
    Write-ReSetLog "Registry value set successfully" "SUCCESS"
} catch {
    Write-ReSetLog "Failed to set registry value: $($_.Exception.Message)" "ERROR"
}
```

### Service Management
```powershell
# Restart service with error handling
try {
    Restart-WindowsService -ServiceName "Spooler"
    Write-Host "Service restarted successfully" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not restart service" -ForegroundColor Yellow
}
```

### File Operations
```powershell
# Safe file operations
$tempFiles = @(
    "$env:TEMP\*",
    "$env:WINDIR\Temp\*"
)

foreach ($path in $tempFiles) {
    try {
        Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "Cleared: $path" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not clear $path" -ForegroundColor Yellow
    }
}
```

## Module Development Guidelines

### New Reset Modules
1. Follow the standard script template
2. Import ReSetUtils.psm1 for utility functions
3. Implement proper error handling and logging
4. Create backups before modifications
5. Use consistent parameter patterns
6. Include comprehensive help documentation

### Utility Function Development
1. Add to ReSetUtils.psm1 module
2. Export in module manifest
3. Follow PowerShell naming conventions
4. Include parameter validation
5. Implement proper error handling
6. Add to module export list

### Testing New Code
1. Test on clean Windows 10/11 systems
2. Verify administrator privilege requirements
3. Test backup and restore functionality
4. Validate error conditions and handling
5. Test with domain and workgroup configurations

This instruction set will help GitHub Copilot understand the project structure, coding standards, and best practices for contributing to the ReSet Toolkit 2.0 project.