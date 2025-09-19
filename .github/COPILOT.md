# Copilot Instructions - ReSet Toolkit 2.0

## Project Context
Enterprise PowerShell toolkit for Windows administration with 49+ functions, Active Directory integration, and comprehensive backup system.

## Key Patterns

### Standard Function Template
```powershell
function Reset-ComponentName {
    [CmdletBinding()]
    param([switch]$Force)
    
    $operationName = "Component Reset"
    try {
        Start-ReSetOperation -Name $operationName
        if (-not $Force) {
            if (-not (Confirm-ReSetOperation -Operation $operationName -Impact "Medium" -Description "Reset description")) {
                return
            }
        }
        New-ReSetBackup -BackupName "ComponentBackup" -RegistryPaths @("HKLM:\Path")
        Write-ProgressStep "Performing reset..."
        # Reset logic here
        Complete-ReSetOperation -Name $operationName -Status "Success"
    } catch {
        Write-ReSetLog "Error: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}
```

### Required Elements
- `#Requires -RunAsAdministrator` for all scripts
- Import `ReSetUtils.psm1` for utilities
- Use `Start-ReSetOperation` and `Complete-ReSetOperation`
- Create backups with `New-ReSetBackup` before changes
- Implement proper error handling and logging
- Use `Write-ProgressStep` for user feedback

### Utility Functions Available
- `Write-ReSetLog` - Logging with levels (INFO, WARN, ERROR, SUCCESS)
- `Test-IsAdmin` / `Assert-AdminRights` - Privilege validation
- `Set-RegistryValue` / `Remove-RegistryValue` - Safe registry operations
- `Restart-WindowsService` - Service management
- `Get-SystemHealth` - System health assessment
- `Test-ActiveDirectoryConnectivity` - AD connectivity testing

See `.github/copilot-instructions.md` for complete guidelines.