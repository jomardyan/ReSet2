#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Group Policy Deployment and Management Script for ReSet Toolkit

.DESCRIPTION
    Comprehensive Group Policy integration script that provides deployment,
    configuration, and management capabilities for enterprise environments.
    Supports silent execution, compliance checking, and centralized configuration.

.AUTHOR
    ReSet Toolkit

.VERSION
    2.0.0

.FUNCTIONS
    - Deploy-ReSetToolkitPolicy
    - Set-ReSetPolicyConfiguration
    - Test-PolicyDeployment
    - Export-PolicyConfiguration
    - Import-PolicyConfiguration
    - Remove-ReSetPolicy
    - Get-PolicyStatus
    - Invoke-PolicyCompliantOperation
#>

# Import utility functions
Import-Module "$PSScriptRoot\ReSetUtils.psm1" -Force

# ===================================================================
# GPO DEPLOYMENT FUNCTIONS
# ===================================================================

function Deploy-ReSetToolkitPolicy {
    <#
    .SYNOPSIS
        Deploys ReSet Toolkit Group Policy settings
    .DESCRIPTION
        Creates registry-based policy settings for enterprise deployment
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$PolicySettings = @{},
        
        [Parameter()]
        [ValidateSet("Computer", "User", "Both")]
        [string]$Scope = "Computer",
        
        [Parameter()]
        [string]$ConfigurationFile,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$ValidateOnly
    )
    
    $operationName = "GPO Policy Deployment"
    
    try {
        Start-ReSetOperation -Name $operationName
        
        # Load configuration from file if provided
        if ($ConfigurationFile -and (Test-Path $ConfigurationFile)) {
            $fileConfig = Get-Content $ConfigurationFile | ConvertFrom-Json
            foreach ($key in $fileConfig.PSObject.Properties.Name) {
                if (-not $PolicySettings.ContainsKey($key)) {
                    $PolicySettings[$key] = $fileConfig.$key
                }
            }
        }
        
        # Default policy settings if none provided
        if ($PolicySettings.Count -eq 0) {
            $PolicySettings = @{
                Enabled = $true
                RequireApproval = $false
                MaintenanceWindow = ""
                DisabledOperations = ""
                BackupRequired = $true
                MaxBackupDays = 90
                LogLevel = "INFO"
                AuditMode = $false
                AllowRemoteExecution = $false
                NotificationLevel = "Normal"
            }
        }
        
        Write-ReSetLog "Deploying ReSet Toolkit Group Policy settings..." "INFO"
        Write-ReSetLog "Scope: $Scope" "INFO"
        Write-ReSetLog "Validation Only: $ValidateOnly" "INFO"
        
        # Validate policy settings
        $validation = Test-PolicyConfiguration -PolicySettings $PolicySettings
        if (-not $validation.Valid) {
            throw "Policy validation failed: $($validation.Errors -join '; ')"
        }
        
        if ($ValidateOnly) {
            Write-ReSetLog "Policy validation completed successfully" "SUCCESS"
            return $validation
        }
        
        # Deploy computer policies
        if ($Scope -eq "Computer" -or $Scope -eq "Both") {
            Write-ProgressStep "Deploying computer policy settings..."
            
            $computerPolicyPath = "HKLM:\SOFTWARE\Policies\ReSetToolkit"
            
            # Create policy registry key
            if (-not (Test-Path $computerPolicyPath)) {
                New-Item -Path $computerPolicyPath -Force | Out-Null
                Write-ReSetLog "Created computer policy registry key" "INFO"
            }
            
            # Set policy values
            foreach ($setting in $PolicySettings.GetEnumerator()) {
                try {
                    $value = $setting.Value
                    $regType = "String"
                    
                    # Determine registry type based on value
                    if ($value -is [bool]) {
                        $value = if ($value) { 1 } else { 0 }
                        $regType = "DWord"
                    } elseif ($value -is [int]) {
                        $regType = "DWord"
                    }
                    
                    Set-RegistryValue -Path $computerPolicyPath -Name $setting.Key -Value $value -Type $regType
                    Write-ReSetLog "Set computer policy: $($setting.Key) = $($setting.Value)" "INFO"
                    
                } catch {
                    Write-ReSetLog "Warning: Could not set policy $($setting.Key): $($_.Exception.Message)" "WARN"
                }
            }
            
            # Set deployment timestamp
            Set-RegistryValue -Path $computerPolicyPath -Name "DeploymentTimestamp" -Value (Get-Date).ToString() -Type "String"
            Set-RegistryValue -Path $computerPolicyPath -Name "DeploymentVersion" -Value "2.0.0" -Type "String"
            
            Write-ReSetLog "Computer policy deployment completed" "SUCCESS"
        }
        
        # Deploy user policies
        if ($Scope -eq "User" -or $Scope -eq "Both") {
            Write-ProgressStep "Deploying user policy settings..."
            
            $userPolicyPath = "HKCU:\SOFTWARE\Policies\ReSetToolkit"
            
            # Create policy registry key
            if (-not (Test-Path $userPolicyPath)) {
                New-Item -Path $userPolicyPath -Force | Out-Null
                Write-ReSetLog "Created user policy registry key" "INFO"
            }
            
            # Set user-specific policy values
            $userSettings = @{
                NotificationLevel = $PolicySettings.NotificationLevel
                AllowUserOverride = $false
            }
            
            foreach ($setting in $userSettings.GetEnumerator()) {
                try {
                    Set-RegistryValue -Path $userPolicyPath -Name $setting.Key -Value $setting.Value -Type "String"
                    Write-ReSetLog "Set user policy: $($setting.Key) = $($setting.Value)" "INFO"
                } catch {
                    Write-ReSetLog "Warning: Could not set user policy $($setting.Key): $($_.Exception.Message)" "WARN"
                }
            }
            
            Write-ReSetLog "User policy deployment completed" "SUCCESS"
        }
        
        # Verify deployment
        Write-ProgressStep "Verifying policy deployment..."
        $verification = Test-PolicyDeployment -Scope $Scope
        
        if ($verification.Success) {
            Write-ReSetLog "Policy deployment verification: PASSED" "SUCCESS"
        } else {
            Write-ReSetLog "Policy deployment verification: FAILED - $($verification.Message)" "ERROR"
        }
        
        # Update toolkit configuration with new policies
        Update-ToolkitConfiguration
        
        Complete-ReSetOperation -Name $operationName -Status "Success"
        
        return @{
            Success = $verification.Success
            Scope = $Scope
            SettingsDeployed = $PolicySettings.Count
            Verification = $verification
        }
        
    } catch {
        Write-ReSetLog "Error deploying Group Policy: $($_.Exception.Message)" "ERROR"
        Complete-ReSetOperation -Name $operationName -Status "Failed" -ErrorMessage $_.Exception.Message
        throw
    }
}

function Test-PolicyConfiguration {
    <#
    .SYNOPSIS
        Validates Group Policy configuration settings
    .DESCRIPTION
        Checks policy settings for consistency and validity
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$PolicySettings
    )
    
    $validation = @{
        Valid = $true
        Errors = @()
        Warnings = @()
    }
    
    try {
        # Validate maintenance window format
        if ($PolicySettings.ContainsKey("MaintenanceWindow") -and $PolicySettings.MaintenanceWindow) {
            $window = $PolicySettings.MaintenanceWindow
            if ($window -notmatch '^\d{1,2}-\d{1,2}$') {
                $validation.Errors += "Invalid maintenance window format: $window (expected HH-HH)"
                $validation.Valid = $false
            } else {
                $parts = $window -split "-"
                $start = [int]$parts[0]
                $end = [int]$parts[1]
                
                if ($start -lt 0 -or $start -gt 23 -or $end -lt 0 -or $end -gt 23) {
                    $validation.Errors += "Maintenance window hours must be between 0-23"
                    $validation.Valid = $false
                }
            }
        }
        
        # Validate log level
        if ($PolicySettings.ContainsKey("LogLevel")) {
            $validLevels = @("ERROR", "WARN", "INFO", "DEBUG")
            if ($PolicySettings.LogLevel -notin $validLevels) {
                $validation.Errors += "Invalid log level: $($PolicySettings.LogLevel) (valid: $($validLevels -join ', '))"
                $validation.Valid = $false
            }
        }
        
        # Validate backup retention
        if ($PolicySettings.ContainsKey("MaxBackupDays")) {
            $days = $PolicySettings.MaxBackupDays
            if ($days -lt 1 -or $days -gt 365) {
                $validation.Errors += "MaxBackupDays must be between 1-365 days"
                $validation.Valid = $false
            }
            
            if ($days -lt 7) {
                $validation.Warnings += "MaxBackupDays less than 7 may not provide adequate recovery time"
            }
        }
        
        # Validate disabled operations
        if ($PolicySettings.ContainsKey("DisabledOperations") -and $PolicySettings.DisabledOperations) {
            $validOperations = @("Reset", "Backup", "Restore", "Cleanup", "All")
            $disabledOps = $PolicySettings.DisabledOperations -split ","
            
            foreach ($op in $disabledOps) {
                $op = $op.Trim()
                if ($op -notin $validOperations) {
                    $validation.Warnings += "Unknown operation type in DisabledOperations: $op"
                }
            }
            
            if ("All" -in $disabledOps) {
                $validation.Warnings += "All operations are disabled - toolkit will not function"
            }
        }
        
        # Validate notification level
        if ($PolicySettings.ContainsKey("NotificationLevel")) {
            $validLevels = @("None", "Minimal", "Normal", "Verbose")
            if ($PolicySettings.NotificationLevel -notin $validLevels) {
                $validation.Errors += "Invalid notification level: $($PolicySettings.NotificationLevel)"
                $validation.Valid = $false
            }
        }
        
        return $validation
        
    } catch {
        $validation.Valid = $false
        $validation.Errors += "Error validating policy configuration: $($_.Exception.Message)"
        return $validation
    }
}

function Test-PolicyDeployment {
    <#
    .SYNOPSIS
        Tests if Group Policy deployment was successful
    .DESCRIPTION
        Verifies that policy settings were correctly applied
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("Computer", "User", "Both")]
        [string]$Scope = "Both"
    )
    
    try {
        $results = @{
            Success = $true
            Message = ""
            ComputerPolicy = @{}
            UserPolicy = @{}
        }
        
        # Test computer policy
        if ($Scope -eq "Computer" -or $Scope -eq "Both") {
            $computerPolicyPath = "HKLM:\SOFTWARE\Policies\ReSetToolkit"
            
            if (Test-Path $computerPolicyPath) {
                $computerPolicy = Get-ItemProperty -Path $computerPolicyPath -ErrorAction SilentlyContinue
                $results.ComputerPolicy = @{
                    Exists = $true
                    Enabled = $computerPolicy.Enabled -eq 1
                    DeploymentTimestamp = $computerPolicy.DeploymentTimestamp
                    SettingsCount = ($computerPolicy | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -notlike "PS*" }).Count
                }
                
                Write-ReSetLog "Computer policy found with $($results.ComputerPolicy.SettingsCount) settings" "INFO"
            } else {
                $results.Success = $false
                $results.Message += "Computer policy not found; "
                $results.ComputerPolicy = @{ Exists = $false }
            }
        }
        
        # Test user policy
        if ($Scope -eq "User" -or $Scope -eq "Both") {
            $userPolicyPath = "HKCU:\SOFTWARE\Policies\ReSetToolkit"
            
            if (Test-Path $userPolicyPath) {
                $userPolicy = Get-ItemProperty -Path $userPolicyPath -ErrorAction SilentlyContinue
                $results.UserPolicy = @{
                    Exists = $true
                    SettingsCount = ($userPolicy | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -notlike "PS*" }).Count
                }
                
                Write-ReSetLog "User policy found with $($results.UserPolicy.SettingsCount) settings" "INFO"
            } else {
                if ($Scope -eq "User") {
                    $results.Success = $false
                    $results.Message += "User policy not found; "
                }
                $results.UserPolicy = @{ Exists = $false }
            }
        }
        
        # Test policy compliance functions
        try {
            $complianceTest = Test-GroupPolicyCompliance -OperationType "Reset"
            if ($complianceTest.Status -eq "Error") {
                $results.Success = $false
                $results.Message += "Policy compliance check failed; "
            }
        } catch {
            $results.Success = $false
            $results.Message += "Policy compliance functions not working; "
        }
        
        if ($results.Success) {
            $results.Message = "Policy deployment verified successfully"
        }
        
        return $results
        
    } catch {
        return @{
            Success = $false
            Message = "Error testing policy deployment: $($_.Exception.Message)"
            ComputerPolicy = @{}
            UserPolicy = @{}
        }
    }
}

function Set-ReSetPolicyConfiguration {
    <#
    .SYNOPSIS
        Sets specific Group Policy configuration values
    .DESCRIPTION
        Allows granular control over individual policy settings
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SettingName,
        
        [Parameter(Mandatory = $true)]
        $SettingValue,
        
        [Parameter()]
        [ValidateSet("Computer", "User")]
        [string]$Scope = "Computer",
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        $policyPath = if ($Scope -eq "Computer") {
            "HKLM:\SOFTWARE\Policies\ReSetToolkit"
        } else {
            "HKCU:\SOFTWARE\Policies\ReSetToolkit"
        }
        
        # Create policy key if it doesn't exist
        if (-not (Test-Path $policyPath)) {
            if (-not $Force) {
                throw "Policy registry key does not exist. Use -Force to create it."
            }
            New-Item -Path $policyPath -Force | Out-Null
            Write-ReSetLog "Created policy registry key: $policyPath" "INFO"
        }
        
        # Determine registry type
        $regType = "String"
        $regValue = $SettingValue
        
        if ($SettingValue -is [bool]) {
            $regValue = if ($SettingValue) { 1 } else { 0 }
            $regType = "DWord"
        } elseif ($SettingValue -is [int]) {
            $regType = "DWord"
        }
        
        # Set the value
        Set-RegistryValue -Path $policyPath -Name $SettingName -Value $regValue -Type $regType
        
        Write-ReSetLog "Set $Scope policy: $SettingName = $SettingValue" "SUCCESS"
        
        # Update toolkit configuration
        Update-ToolkitConfiguration
        
        return $true
        
    } catch {
        Write-ReSetLog "Error setting policy configuration: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Export-PolicyConfiguration {
    <#
    .SYNOPSIS
        Exports current Group Policy configuration to file
    .DESCRIPTION
        Creates exportable configuration files for deployment
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExportPath,
        
        [Parameter()]
        [ValidateSet("JSON", "XML", "REG")]
        [string]$Format = "JSON",
        
        [Parameter()]
        [ValidateSet("Computer", "User", "Both")]
        [string]$Scope = "Both"
    )
    
    try {
        $config = Get-GroupPolicyConfiguration
        
        $exportData = @{
            ExportTimestamp = Get-Date
            ExportVersion = "2.0.0"
            Scope = $Scope
            ComputerPolicy = if ($Scope -eq "Computer" -or $Scope -eq "Both") { $config.ComputerPolicy } else { $null }
            UserPolicy = if ($Scope -eq "User" -or $Scope -eq "Both") { $config.UserPolicy } else { $null }
            EffectiveSettings = $config.EffectiveSettings
        }
        
        switch ($Format) {
            "JSON" {
                $exportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $ExportPath -Encoding UTF8
            }
            "XML" {
                $exportData | ConvertTo-Xml -Depth 10 | Out-File -FilePath $ExportPath -Encoding UTF8
            }
            "REG" {
                Export-RegistryConfiguration -ExportData $exportData -FilePath $ExportPath
            }
        }
        
        Write-ReSetLog "Policy configuration exported to: $ExportPath" "SUCCESS"
        return $ExportPath
        
    } catch {
        Write-ReSetLog "Error exporting policy configuration: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Import-PolicyConfiguration {
    <#
    .SYNOPSIS
        Imports Group Policy configuration from file
    .DESCRIPTION
        Deploys policies from previously exported configuration files
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImportPath,
        
        [Parameter()]
        [ValidateSet("JSON", "XML", "REG")]
        [string]$Format = "JSON",
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$ValidateOnly
    )
    
    try {
        if (-not (Test-Path $ImportPath)) {
            throw "Import file not found: $ImportPath"
        }
        
        $importData = switch ($Format) {
            "JSON" {
                Get-Content $ImportPath | ConvertFrom-Json
            }
            "XML" {
                [xml](Get-Content $ImportPath)
            }
            "REG" {
                Import-RegistryConfiguration -FilePath $ImportPath
            }
        }
        
        Write-ReSetLog "Importing policy configuration from: $ImportPath" "INFO"
        
        # Validate imported data
        if ($importData.ComputerPolicy) {
            $validation = Test-PolicyConfiguration -PolicySettings $importData.ComputerPolicy
            if (-not $validation.Valid) {
                throw "Imported computer policy validation failed: $($validation.Errors -join '; ')"
            }
        }
        
        if ($ValidateOnly) {
            Write-ReSetLog "Policy import validation completed successfully" "SUCCESS"
            return $validation
        }
        
        # Deploy imported policies
        $deploymentScope = "Both"
        if ($importData.ComputerPolicy -and -not $importData.UserPolicy) {
            $deploymentScope = "Computer"
        } elseif ($importData.UserPolicy -and -not $importData.ComputerPolicy) {
            $deploymentScope = "User"
        }
        
        $result = Deploy-ReSetToolkitPolicy -PolicySettings $importData.ComputerPolicy -Scope $deploymentScope -Force:$Force
        
        Write-ReSetLog "Policy configuration imported successfully" "SUCCESS"
        return $result
        
    } catch {
        Write-ReSetLog "Error importing policy configuration: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Remove-ReSetPolicy {
    <#
    .SYNOPSIS
        Removes ReSet Toolkit Group Policy settings
    .DESCRIPTION
        Cleanly removes all policy registry entries
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("Computer", "User", "Both")]
        [string]$Scope = "Both",
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        if (-not $Force) {
            $confirm = Read-Host "Are you sure you want to remove ReSet Toolkit Group Policy settings? (y/N)"
            if ($confirm.ToLower() -ne "y") {
                Write-ReSetLog "Policy removal cancelled by user" "INFO"
                return
            }
        }
        
        $removed = @()
        
        # Remove computer policy
        if ($Scope -eq "Computer" -or $Scope -eq "Both") {
            $computerPolicyPath = "HKLM:\SOFTWARE\Policies\ReSetToolkit"
            if (Test-Path $computerPolicyPath) {
                Remove-Item -Path $computerPolicyPath -Recurse -Force
                $removed += "Computer"
                Write-ReSetLog "Computer policy registry key removed" "SUCCESS"
            }
        }
        
        # Remove user policy
        if ($Scope -eq "User" -or $Scope -eq "Both") {
            $userPolicyPath = "HKCU:\SOFTWARE\Policies\ReSetToolkit"
            if (Test-Path $userPolicyPath) {
                Remove-Item -Path $userPolicyPath -Recurse -Force
                $removed += "User"
                Write-ReSetLog "User policy registry key removed" "SUCCESS"
            }
        }
        
        if ($removed.Count -gt 0) {
            Write-ReSetLog "ReSet Toolkit Group Policy settings removed: $($removed -join ', ')" "SUCCESS"
            
            # Update toolkit configuration
            Update-ToolkitConfiguration
        } else {
            Write-ReSetLog "No ReSet Toolkit Group Policy settings found to remove" "INFO"
        }
        
        return $removed
        
    } catch {
        Write-ReSetLog "Error removing Group Policy settings: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Get-PolicyStatus {
    <#
    .SYNOPSIS
        Gets comprehensive status of Group Policy deployment
    .DESCRIPTION
        Provides detailed information about current policy state
    #>
    [CmdletBinding()]
    param()
    
    try {
        $status = @{
            Timestamp = Get-Date
            Computer = $env:COMPUTERNAME
            User = $env:USERNAME
            Domain = $env:USERDOMAIN
        }
        
        # Get policy configuration
        $config = Get-GroupPolicyConfiguration
        $status.PolicyConfiguration = $config
        
        # Test compliance
        $status.ComplianceTests = @{
            Reset = Test-GroupPolicyCompliance -OperationType "Reset"
            Backup = Test-GroupPolicyCompliance -OperationType "Backup"
            Restore = Test-GroupPolicyCompliance -OperationType "Restore"
            Cleanup = Test-GroupPolicyCompliance -OperationType "Cleanup"
        }
        
        # Test maintenance window
        $status.MaintenanceWindow = Test-MaintenanceWindow
        
        # Test deployment
        $status.Deployment = Test-PolicyDeployment -Scope "Both"
        
        # Get last GP refresh
        try {
            $gpResult = & gpupdate /? 2>&1
            $status.GroupPolicyInfo = "Available"
        } catch {
            $status.GroupPolicyInfo = "Not Available"
        }
        
        return $status
        
    } catch {
        Write-ReSetLog "Error getting policy status: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Invoke-PolicyCompliantOperation {
    <#
    .SYNOPSIS
        Executes operations with full Group Policy compliance checking
    .DESCRIPTION
        Wrapper function that ensures all operations comply with policies
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationType,
        
        [Parameter(Mandatory = $true)]
        [string]$OperationName,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Operation,
        
        [Parameter()]
        [hashtable]$Parameters = @{},
        
        [Parameter()]
        [switch]$IgnoreMaintenanceWindow
    )
    
    try {
        # Check Group Policy compliance
        Assert-GroupPolicyCompliance -OperationType $OperationType -OperationName $OperationName -IgnoreMaintenanceWindow:$IgnoreMaintenanceWindow
        
        # Execute operation with audit logging
        Write-GroupPolicyAuditLog -OperationType $OperationType -OperationName $OperationName -Status "Started"
        
        $result = & $Operation @Parameters
        
        Write-GroupPolicyAuditLog -OperationType $OperationType -OperationName $OperationName -Status "Completed" -Details "Operation completed successfully"
        
        return $result
        
    } catch {
        Write-GroupPolicyAuditLog -OperationType $OperationType -OperationName $OperationName -Status "Failed" -Details $_.Exception.Message
        Write-ReSetLog "Policy compliant operation failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Helper function for registry export
function Export-RegistryConfiguration {
    param(
        [hashtable]$ExportData,
        [string]$FilePath
    )
    
    $regContent = @"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\ReSetToolkit]
"@
    
    foreach ($setting in $ExportData.ComputerPolicy.GetEnumerator()) {
        if ($setting.Value -is [bool]) {
            $value = if ($setting.Value) { "dword:00000001" } else { "dword:00000000" }
        } elseif ($setting.Value -is [int]) {
            $value = "dword:$($setting.Value.ToString('x8'))"
        } else {
            $value = "`"$($setting.Value)`""
        }
        $regContent += "`n`"$($setting.Key)`"=$value"
    }
    
    $regContent | Out-File -FilePath $FilePath -Encoding ASCII
}

# Helper function for registry import
function Import-RegistryConfiguration {
    param([string]$FilePath)
    
    # This would parse .reg files - simplified for demonstration
    throw "REG file import not yet implemented"
}

# ===================================================================
# EXPORT FUNCTIONS
# ===================================================================

Write-Host "Group Policy Deployment Functions Loaded" -ForegroundColor Green
Write-Host "Functions: Deploy-ReSetToolkitPolicy, Set-ReSetPolicyConfiguration," -ForegroundColor Gray
Write-Host "          Test-PolicyDeployment, Export-PolicyConfiguration," -ForegroundColor Gray
Write-Host "          Import-PolicyConfiguration, Remove-ReSetPolicy," -ForegroundColor Gray
Write-Host "          Get-PolicyStatus, Invoke-PolicyCompliantOperation" -ForegroundColor Gray