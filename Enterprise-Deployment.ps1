#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enterprise Deployment Script for ReSet Toolkit

.DESCRIPTION
    Comprehensive deployment script for enterprise environments supporting:
    - Silent installation via Group Policy
    - MSI package creation
    - Configuration deployment
    - Domain-wide distribution
    - Automated scheduled tasks

.AUTHOR
    ReSet Toolkit

.VERSION
    2.0.0

.PARAMETER InstallationType
    Type of installation: Silent, Interactive, MSI, GPO, SCCM

.PARAMETER DeploymentScope
    Scope of deployment: Local, Domain, OU

.PARAMETER ConfigurationProfile
    Predefined configuration profile: Default, Secure, Minimal, Complete

.EXAMPLE
    .\Enterprise-Deployment.ps1 -InstallationType Silent -DeploymentScope Domain -ConfigurationProfile Secure
#>

param(
    [Parameter()]
    [ValidateSet("Silent", "Interactive", "MSI", "GPO", "SCCM")]
    [string]$InstallationType = "Silent",
    
    [Parameter()]
    [ValidateSet("Local", "Domain", "OU")]
    [string]$DeploymentScope = "Local",
    
    [Parameter()]
    [ValidateSet("Default", "Secure", "Minimal", "Complete")]
    [string]$ConfigurationProfile = "Default",
    
    [Parameter()]
    [string]$InstallPath = "$env:ProgramFiles\ReSetToolkit",
    
    [Parameter()]
    [string]$ConfigurationFile,
    
    [Parameter()]
    [string]$TargetOU,
    
    [Parameter()]
    [switch]$CreateScheduledTasks,
    
    [Parameter()]
    [switch]$DeployPolicies,
    
    [Parameter()]
    [switch]$EnableAuditing,
    
    [Parameter()]
    [switch]$ValidateOnly,
    
    [Parameter()]
    [switch]$Force
)

# Import utility module if available
$utilsPath = Join-Path $PSScriptRoot "scripts\ReSetUtils.psm1"
if (Test-Path $utilsPath) {
    Import-Module $utilsPath -Force
} else {
    # Standalone deployment - define minimal functions
    function Write-DeploymentLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        Write-Host $logEntry -ForegroundColor $(
            switch($Level) {
                "ERROR" { "Red" }
                "WARN" { "Yellow" }
                "SUCCESS" { "Green" }
                default { "Cyan" }
            }
        )
    }
}

# ===================================================================
# DEPLOYMENT CONFIGURATION PROFILES
# ===================================================================

$ConfigurationProfiles = @{
    "Default" = @{
        Enabled = $true
        RequireApproval = $false
        MaintenanceWindow = ""
        BackupRequired = $true
        MaxBackupDays = 90
        LogLevel = "INFO"
        AuditMode = $false
        AllowRemoteExecution = $false
        EnableSilentMode = $true
        NotificationLevel = "Normal"
        AutoBackup = $true
        EnableEventLogging = $true
        ExecutionTimeout = 30
    }
    
    "Secure" = @{
        Enabled = $true
        RequireApproval = $true
        MaintenanceWindow = "22-06"
        BackupRequired = $true
        MaxBackupDays = 180
        LogLevel = "INFO"
        AuditMode = $true
        AllowRemoteExecution = $false
        EnableSilentMode = $true
        NotificationLevel = "Minimal"
        AutoBackup = $true
        EnableEventLogging = $true
        ExecutionTimeout = 20
    }
    
    "Minimal" = @{
        Enabled = $true
        RequireApproval = $false
        MaintenanceWindow = ""
        BackupRequired = $false
        MaxBackupDays = 30
        LogLevel = "WARN"
        AuditMode = $false
        AllowRemoteExecution = $false
        EnableSilentMode = $true
        NotificationLevel = "None"
        AutoBackup = $false
        EnableEventLogging = $false
        ExecutionTimeout = 15
    }
    
    "Complete" = @{
        Enabled = $true
        RequireApproval = $false
        MaintenanceWindow = ""
        BackupRequired = $true
        MaxBackupDays = 365
        LogLevel = "DEBUG"
        AuditMode = $true
        AllowRemoteExecution = $true
        EnableSilentMode = $true
        NotificationLevel = "Verbose"
        AutoBackup = $true
        EnableEventLogging = $true
        ExecutionTimeout = 60
    }
}

# ===================================================================
# MAIN DEPLOYMENT FUNCTIONS
# ===================================================================

function Start-EnterpriseDeployment {
    <#
    .SYNOPSIS
        Main deployment orchestration function
    #>
    
    try {
        Write-DeploymentLog "Starting ReSet Toolkit Enterprise Deployment" "INFO"
        Write-DeploymentLog "Installation Type: $InstallationType" "INFO"
        Write-DeploymentLog "Deployment Scope: $DeploymentScope" "INFO"
        Write-DeploymentLog "Configuration Profile: $ConfigurationProfile" "INFO"
        
        # Validate environment
        if (-not (Test-DeploymentEnvironment)) {
            throw "Environment validation failed"
        }
        
        # Load configuration
        $config = Get-DeploymentConfiguration
        
        if ($ValidateOnly) {
            Write-DeploymentLog "Validation mode - no changes will be made" "INFO"
            $validation = Test-DeploymentConfiguration -Configuration $config
            return $validation
        }
        
        # Execute deployment based on type
        switch ($InstallationType) {
            "Silent" {
                Invoke-SilentDeployment -Configuration $config
            }
            "Interactive" {
                Invoke-InteractiveDeployment -Configuration $config
            }
            "MSI" {
                New-MSIPackage -Configuration $config
            }
            "GPO" {
                Deploy-GroupPolicyInstallation -Configuration $config
            }
            "SCCM" {
                New-SCCMPackage -Configuration $config
            }
        }
        
        # Deploy policies if requested
        if ($DeployPolicies) {
            Deploy-EnterprisePolicy -Configuration $config
        }
        
        # Create scheduled tasks if requested
        if ($CreateScheduledTasks) {
            New-MaintenanceTasks -Configuration $config
        }
        
        # Verify deployment
        $verification = Test-DeploymentSuccess
        
        Write-DeploymentLog "Enterprise deployment completed: $($verification.Status)" "SUCCESS"
        return $verification
        
    } catch {
        Write-DeploymentLog "Enterprise deployment failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Test-DeploymentEnvironment {
    <#
    .SYNOPSIS
        Validates deployment environment prerequisites
    #>
    
    try {
        $validation = @{
            Valid = $true
            Issues = @()
        }
        
        # Check PowerShell version
        if ($PSVersionTable.PSVersion.Major -lt 5) {
            $validation.Issues += "PowerShell 5.0 or higher required"
            $validation.Valid = $false
        }
        
        # Check administrative rights
        $currentPrincipal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            $validation.Issues += "Administrative privileges required"
            $validation.Valid = $false
        }
        
        # Check disk space (minimum 100MB)
        $installDrive = Split-Path $InstallPath -Qualifier
        $freeSpace = (Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $installDrive }).FreeSpace
        if ($freeSpace -lt 100MB) {
            $validation.Issues += "Insufficient disk space (minimum 100MB required)"
            $validation.Valid = $false
        }
        
        # Check domain membership for domain deployments
        if ($DeploymentScope -eq "Domain") {
            $computerSystem = Get-ComputerInfo
            if (-not $computerSystem.PartOfDomain) {
                $validation.Issues += "Computer must be domain-joined for domain deployment"
                $validation.Valid = $false
            }
        }
        
        # Check Group Policy prerequisites
        if ($InstallationType -eq "GPO" -or $DeployPolicies) {
            try {
                $gpResult = & gpupdate /? 2>&1
                if ($LASTEXITCODE -ne 0) {
                    $validation.Issues += "Group Policy tools not available"
                }
            } catch {
                $validation.Issues += "Group Policy tools not accessible"
            }
        }
        
        Write-DeploymentLog "Environment validation: $(if($validation.Valid){'PASSED'}else{'FAILED'})" $(if($validation.Valid){'SUCCESS'}else{'ERROR'})
        
        foreach ($issue in $validation.Issues) {
            Write-DeploymentLog "Validation issue: $issue" "WARN"
        }
        
        return $validation.Valid
        
    } catch {
        Write-DeploymentLog "Environment validation error: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-DeploymentConfiguration {
    <#
    .SYNOPSIS
        Gets deployment configuration from profile and files
    #>
    
    try {
        # Start with profile configuration
        $config = $ConfigurationProfiles[$ConfigurationProfile].Clone()
        
        # Override with file configuration if provided
        if ($ConfigurationFile -and (Test-Path $ConfigurationFile)) {
            $fileConfig = Get-Content $ConfigurationFile | ConvertFrom-Json
            foreach ($key in $fileConfig.PSObject.Properties.Name) {
                $config[$key] = $fileConfig.$key
            }
            Write-DeploymentLog "Configuration loaded from file: $ConfigurationFile" "INFO"
        }
        
        # Apply command-line overrides
        if ($EnableAuditing) {
            $config.AuditMode = $true
            $config.EnableEventLogging = $true
        }
        
        # Add deployment-specific settings
        $config.InstallPath = $InstallPath
        $config.DeploymentScope = $DeploymentScope
        $config.InstallationType = $InstallationType
        
        Write-DeploymentLog "Configuration profile '$ConfigurationProfile' loaded with $($config.Count) settings" "INFO"
        
        return $config
        
    } catch {
        Write-DeploymentLog "Error loading deployment configuration: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Invoke-SilentDeployment {
    <#
    .SYNOPSIS
        Performs silent installation suitable for automated deployment
    #>
    param(
        [hashtable]$Configuration
    )
    
    try {
        Write-DeploymentLog "Starting silent deployment..." "INFO"
        
        # Create installation directory
        if (-not (Test-Path $Configuration.InstallPath)) {
            New-Item -ItemType Directory -Path $Configuration.InstallPath -Force | Out-Null
            Write-DeploymentLog "Created installation directory: $($Configuration.InstallPath)" "INFO"
        }
        
        # Copy toolkit files
        $sourcePath = $PSScriptRoot
        $destinationPath = $Configuration.InstallPath
        
        # Copy main files
        $mainFiles = @(
            "Reset-Manager.ps1",
            "README.md",
            "LICENSE"
        )
        
        foreach ($file in $mainFiles) {
            $sourceFile = Join-Path $sourcePath $file
            $destFile = Join-Path $destinationPath $file
            
            if (Test-Path $sourceFile) {
                Copy-Item -Path $sourceFile -Destination $destFile -Force
                Write-DeploymentLog "Copied: $file" "INFO"
            }
        }
        
        # Copy scripts directory
        $scriptsSource = Join-Path $sourcePath "scripts"
        $scriptsDest = Join-Path $destinationPath "scripts"
        
        if (Test-Path $scriptsSource) {
            if (Test-Path $scriptsDest) {
                Remove-Item -Path $scriptsDest -Recurse -Force
            }
            Copy-Item -Path $scriptsSource -Destination $scriptsDest -Recurse -Force
            Write-DeploymentLog "Copied scripts directory" "INFO"
        }
        
        # Create required directories
        $directories = @("logs", "backups", "config", "temp", "reports")
        foreach ($dir in $directories) {
            $dirPath = Join-Path $destinationPath $dir
            if (-not (Test-Path $dirPath)) {
                New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
                Write-DeploymentLog "Created directory: $dir" "INFO"
            }
        }
        
        # Deploy configuration
        Deploy-ToolkitConfiguration -Configuration $Configuration
        
        # Create shortcuts
        New-DesktopShortcuts -InstallPath $Configuration.InstallPath
        
        # Register with Windows
        Register-ToolkitWithWindows -InstallPath $Configuration.InstallPath
        
        Write-DeploymentLog "Silent deployment completed successfully" "SUCCESS"
        
    } catch {
        Write-DeploymentLog "Silent deployment failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Deploy-ToolkitConfiguration {
    <#
    .SYNOPSIS
        Deploys toolkit configuration based on deployment settings
    #>
    param(
        [hashtable]$Configuration
    )
    
    try {
        Write-DeploymentLog "Deploying toolkit configuration..." "INFO"
        
        # Create configuration file
        $configPath = Join-Path $Configuration.InstallPath "config\deployment-config.json"
        $Configuration | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
        
        # Deploy Group Policy settings if in domain
        if ($Configuration.DeploymentScope -eq "Domain" -or $Configuration.DeploymentScope -eq "OU") {
            Deploy-GroupPolicyConfiguration -Configuration $Configuration
        } else {
            # Deploy local registry configuration
            Deploy-LocalConfiguration -Configuration $Configuration
        }
        
        Write-DeploymentLog "Configuration deployment completed" "SUCCESS"
        
    } catch {
        Write-DeploymentLog "Configuration deployment failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Deploy-GroupPolicyConfiguration {
    <#
    .SYNOPSIS
        Deploys configuration via Group Policy registry settings
    #>
    param(
        [hashtable]$Configuration
    )
    
    try {
        Write-DeploymentLog "Deploying Group Policy configuration..." "INFO"
        
        $policyPath = "HKLM:\SOFTWARE\Policies\ReSetToolkit"
        
        # Create policy registry key
        if (-not (Test-Path $policyPath)) {
            New-Item -Path $policyPath -Force | Out-Null
        }
        
        # Deploy each configuration setting
        foreach ($setting in $Configuration.GetEnumerator()) {
            if ($setting.Key -in @("InstallPath", "DeploymentScope", "InstallationType")) {
                continue  # Skip deployment-specific settings
            }
            
            try {
                $value = $setting.Value
                $regType = "String"
                
                if ($value -is [bool]) {
                    $value = if ($value) { 1 } else { 0 }
                    $regType = "DWord"
                } elseif ($value -is [int]) {
                    $regType = "DWord"
                }
                
                Set-ItemProperty -Path $policyPath -Name $setting.Key -Value $value -Type $regType -Force
                Write-DeploymentLog "Set Group Policy: $($setting.Key) = $($setting.Value)" "INFO"
                
            } catch {
                Write-DeploymentLog "Warning: Could not set Group Policy $($setting.Key): $($_.Exception.Message)" "WARN"
            }
        }
        
        # Set deployment metadata
        Set-ItemProperty -Path $policyPath -Name "DeploymentTimestamp" -Value (Get-Date).ToString() -Type String -Force
        Set-ItemProperty -Path $policyPath -Name "DeploymentVersion" -Value "2.0.0" -Type String -Force
        Set-ItemProperty -Path $policyPath -Name "ConfigurationProfile" -Value $ConfigurationProfile -Type String -Force
        
        Write-DeploymentLog "Group Policy configuration deployed successfully" "SUCCESS"
        
    } catch {
        Write-DeploymentLog "Group Policy configuration deployment failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Deploy-LocalConfiguration {
    <#
    .SYNOPSIS
        Deploys configuration to local registry for standalone installations
    #>
    param(
        [hashtable]$Configuration
    )
    
    try {
        Write-DeploymentLog "Deploying local configuration..." "INFO"
        
        $configPath = "HKLM:\SOFTWARE\ReSetToolkit"
        
        # Create configuration registry key
        if (-not (Test-Path $configPath)) {
            New-Item -Path $configPath -Force | Out-Null
        }
        
        # Deploy configuration settings
        foreach ($setting in $Configuration.GetEnumerator()) {
            try {
                $value = $setting.Value
                $regType = "String"
                
                if ($value -is [bool]) {
                    $value = if ($value) { 1 } else { 0 }
                    $regType = "DWord"
                } elseif ($value -is [int]) {
                    $regType = "DWord"
                }
                
                Set-ItemProperty -Path $configPath -Name $setting.Key -Value $value -Type $regType -Force
                
            } catch {
                Write-DeploymentLog "Warning: Could not set configuration $($setting.Key): $($_.Exception.Message)" "WARN"
            }
        }
        
        Write-DeploymentLog "Local configuration deployed successfully" "SUCCESS"
        
    } catch {
        Write-DeploymentLog "Local configuration deployment failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function New-DesktopShortcuts {
    <#
    .SYNOPSIS
        Creates desktop shortcuts for the toolkit
    #>
    param(
        [string]$InstallPath
    )
    
    try {
        $shell = New-Object -ComObject WScript.Shell
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        
        # Main toolkit shortcut
        $shortcutPath = Join-Path $desktopPath "ReSet Toolkit.lnk"
        $targetPath = Join-Path $InstallPath "Reset-Manager.ps1"
        
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$targetPath`""
        $shortcut.WorkingDirectory = $InstallPath
        $shortcut.Description = "Windows Reset Toolkit"
        $shortcut.Save()
        
        Write-DeploymentLog "Created desktop shortcut: ReSet Toolkit.lnk" "INFO"
        
    } catch {
        Write-DeploymentLog "Warning: Could not create desktop shortcuts: $($_.Exception.Message)" "WARN"
    }
}

function Register-ToolkitWithWindows {
    <#
    .SYNOPSIS
        Registers the toolkit with Windows for proper integration
    #>
    param(
        [string]$InstallPath
    )
    
    try {
        # Add to Programs and Features
        $uninstallPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ReSetToolkit"
        
        if (-not (Test-Path $uninstallPath)) {
            New-Item -Path $uninstallPath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $uninstallPath -Name "DisplayName" -Value "Windows Reset Toolkit" -Type String
        Set-ItemProperty -Path $uninstallPath -Name "DisplayVersion" -Value "2.0.0" -Type String
        Set-ItemProperty -Path $uninstallPath -Name "Publisher" -Value "ReSet Toolkit" -Type String
        Set-ItemProperty -Path $uninstallPath -Name "InstallLocation" -Value $InstallPath -Type String
        Set-ItemProperty -Path $uninstallPath -Name "InstallDate" -Value (Get-Date -Format "yyyyMMdd") -Type String
        
        # Create Event Log source
        try {
            if (-not [System.Diagnostics.EventLog]::SourceExists("ReSetToolkit")) {
                New-EventLog -LogName "Application" -Source "ReSetToolkit"
                Write-DeploymentLog "Created Event Log source: ReSetToolkit" "INFO"
            }
        } catch {
            Write-DeploymentLog "Warning: Could not create Event Log source: $($_.Exception.Message)" "WARN"
        }
        
        Write-DeploymentLog "Toolkit registered with Windows successfully" "SUCCESS"
        
    } catch {
        Write-DeploymentLog "Warning: Could not fully register with Windows: $($_.Exception.Message)" "WARN"
    }
}

function Test-DeploymentSuccess {
    <#
    .SYNOPSIS
        Verifies that deployment was successful
    #>
    
    try {
        $verification = @{
            Status = "Success"
            Issues = @()
            InstalledComponents = @()
        }
        
        # Check installation directory
        if (Test-Path $InstallPath) {
            $verification.InstalledComponents += "Installation directory"
        } else {
            $verification.Issues += "Installation directory not found"
            $verification.Status = "Failed"
        }
        
        # Check main script
        $mainScript = Join-Path $InstallPath "Reset-Manager.ps1"
        if (Test-Path $mainScript) {
            $verification.InstalledComponents += "Main script"
        } else {
            $verification.Issues += "Main script not found"
            $verification.Status = "Failed"
        }
        
        # Check utilities module
        $utilsModule = Join-Path $InstallPath "scripts\ReSetUtils.psm1"
        if (Test-Path $utilsModule) {
            $verification.InstalledComponents += "Utilities module"
        } else {
            $verification.Issues += "Utilities module not found"
            $verification.Status = "Failed"
        }
        
        # Check configuration
        $configExists = (Test-Path "HKLM:\SOFTWARE\Policies\ReSetToolkit") -or (Test-Path "HKLM:\SOFTWARE\ReSetToolkit")
        if ($configExists) {
            $verification.InstalledComponents += "Configuration"
        } else {
            $verification.Issues += "Configuration not deployed"
        }
        
        Write-DeploymentLog "Deployment verification: $($verification.Status)" $(if($verification.Status -eq "Success"){'SUCCESS'}else{'ERROR'})
        
        return $verification
        
    } catch {
        Write-DeploymentLog "Deployment verification error: $($_.Exception.Message)" "ERROR"
        return @{
            Status = "Error"
            Issues = @("Verification failed: $($_.Exception.Message)")
            InstalledComponents = @()
        }
    }
}

# ===================================================================
# MAIN EXECUTION
# ===================================================================

if ($MyInvocation.InvocationName -ne ".") {
    try {
        $result = Start-EnterpriseDeployment
        
        if ($result.Status -eq "Success") {
            Write-DeploymentLog "✅ Enterprise deployment completed successfully!" "SUCCESS"
            exit 0
        } else {
            Write-DeploymentLog "❌ Enterprise deployment completed with issues" "WARN"
            exit 1
        }
        
    } catch {
        Write-DeploymentLog "❌ Enterprise deployment failed: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}
