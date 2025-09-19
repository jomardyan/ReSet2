#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Example GPO deployment scenarios for ReSet Toolkit

.DESCRIPTION
    Collection of example scripts demonstrating common Group Policy
    deployment scenarios for different organizational environments.

.AUTHOR
    ReSet Toolkit Examples

.VERSION
    2.0.0
#>

# Import required modules
$utilsPath = Join-Path $PSScriptRoot "..\..\..\scripts\ReSetUtils.psm1"
if (Test-Path $utilsPath) {
    Import-Module $utilsPath -Force
}

# ===================================================================
# EXAMPLE 1: SECURE ENTERPRISE DEPLOYMENT
# ===================================================================

function Deploy-SecureEnterprise {
    <#
    .SYNOPSIS
        Deploys ReSet Toolkit with maximum security settings
    .DESCRIPTION
        Suitable for: Financial institutions, healthcare, government
        Features: Approval required, audit logging, maintenance windows
    #>
    
    Write-Host "🔒 Deploying Secure Enterprise Configuration..." -ForegroundColor Green
    
    $secureConfig = @{
        # Core Settings
        Enabled = $true
        RequireApproval = $true
        
        # Security Controls
        MaintenanceWindow = "02-04"  # 2 AM to 4 AM only
        DisabledOperations = "Cleanup"  # Disable potentially risky operations
        AllowRemoteExecution = $false
        AllowUserOverride = $false
        
        # Backup and Recovery
        BackupRequired = $true
        AutoBackup = $true
        MaxBackupDays = 365  # Long retention for compliance
        
        # Auditing and Compliance
        AuditMode = $true
        EnableEventLogging = $true
        LogLevel = "INFO"
        
        # User Experience
        EnableSilentMode = $true
        NotificationLevel = "Minimal"
        ExecutionTimeout = 20  # Conservative timeout
    }
    
    try {
        # Deploy policy
        Deploy-ReSetToolkitPolicy -PolicySettings $secureConfig -Scope Computer -Force
        
        # Create approval process
        New-ApprovalWorkflow -RequireJustification $true -NotifyAdministrators $true
        
        # Setup compliance monitoring
        New-ComplianceMonitoring -AlertOnViolations $true -ReportingFrequency "Daily"
        
        Write-Host "✅ Secure Enterprise deployment completed" -ForegroundColor Green
        Write-Host "📋 Configuration Summary:" -ForegroundColor Cyan
        Write-Host "   • Approval required for all operations" -ForegroundColor White
        Write-Host "   • Operations limited to 2-4 AM maintenance window" -ForegroundColor White
        Write-Host "   • Comprehensive audit logging enabled" -ForegroundColor White
        Write-Host "   • 365-day backup retention" -ForegroundColor White
        Write-Host "   • Cleanup operations disabled" -ForegroundColor White
        
    } catch {
        Write-Error "Secure deployment failed: $($_.Exception.Message)"
    }
}

# ===================================================================
# EXAMPLE 2: DEVELOPMENT ENVIRONMENT
# ===================================================================

function Deploy-DevelopmentEnvironment {
    <#
    .SYNOPSIS
        Deploys ReSet Toolkit for development teams
    .DESCRIPTION
        Suitable for: Development workstations, testing environments
        Features: Relaxed settings, debug logging, remote execution
    #>
    
    Write-Host "🛠️ Deploying Development Environment Configuration..." -ForegroundColor Green
    
    $devConfig = @{
        # Core Settings
        Enabled = $true
        RequireApproval = $false
        
        # Flexible Operations
        MaintenanceWindow = ""  # No time restrictions
        DisabledOperations = ""  # All operations allowed
        AllowRemoteExecution = $true
        AllowUserOverride = $true
        
        # Backup and Recovery
        BackupRequired = $true
        AutoBackup = $true
        MaxBackupDays = 30  # Shorter retention for dev
        
        # Development Features
        AuditMode = $false
        EnableEventLogging = $true
        LogLevel = "DEBUG"  # Detailed logging for troubleshooting
        
        # User Experience
        EnableSilentMode = $true
        NotificationLevel = "Verbose"
        ExecutionTimeout = 60  # Longer timeout for complex operations
    }
    
    try {
        # Deploy policy
        Deploy-ReSetToolkitPolicy -PolicySettings $devConfig -Scope Computer -Force
        
        # Create development shortcuts
        New-DevelopmentShortcuts
        
        # Setup debug logging
        Enable-DebugLogging -LogPath "C:\DevLogs\ReSetToolkit"
        
        Write-Host "✅ Development environment deployment completed" -ForegroundColor Green
        Write-Host "📋 Configuration Summary:" -ForegroundColor Cyan
        Write-Host "   • No approval required" -ForegroundColor White
        Write-Host "   • All operations available 24/7" -ForegroundColor White
        Write-Host "   • Debug logging enabled" -ForegroundColor White
        Write-Host "   • Remote execution allowed" -ForegroundColor White
        Write-Host "   • User overrides permitted" -ForegroundColor White
        
    } catch {
        Write-Error "Development deployment failed: $($_.Exception.Message)"
    }
}

# ===================================================================
# EXAMPLE 3: STANDARD OFFICE DEPLOYMENT
# ===================================================================

function Deploy-StandardOffice {
    <#
    .SYNOPSIS
        Deploys ReSet Toolkit for standard office environments
    .DESCRIPTION
        Suitable for: General office workstations, administrative staff
        Features: Balanced security and usability
    #>
    
    Write-Host "🏢 Deploying Standard Office Configuration..." -ForegroundColor Green
    
    $officeConfig = @{
        # Core Settings
        Enabled = $true
        RequireApproval = $false
        
        # Balanced Security
        MaintenanceWindow = "18-08"  # After hours: 6 PM to 8 AM
        DisabledOperations = ""  # Most operations allowed
        AllowRemoteExecution = $false
        AllowUserOverride = $false
        
        # Backup and Recovery
        BackupRequired = $true
        AutoBackup = $true
        MaxBackupDays = 90  # Standard retention
        
        # Monitoring
        AuditMode = $true
        EnableEventLogging = $true
        LogLevel = "INFO"
        
        # User Experience
        EnableSilentMode = $true
        NotificationLevel = "Normal"
        ExecutionTimeout = 30
    }
    
    try {
        # Deploy policy
        Deploy-ReSetToolkitPolicy -PolicySettings $officeConfig -Scope Computer -Force
        
        # Create user training materials
        New-UserTrainingMaterials
        
        # Setup help desk integration
        Enable-HelpDeskIntegration
        
        Write-Host "✅ Standard Office deployment completed" -ForegroundColor Green
        Write-Host "📋 Configuration Summary:" -ForegroundColor Cyan
        Write-Host "   • Operations allowed during extended hours (6 PM - 8 AM)" -ForegroundColor White
        Write-Host "   • Standard audit logging" -ForegroundColor White
        Write-Host "   • 90-day backup retention" -ForegroundColor White
        Write-Host "   • Normal user notifications" -ForegroundColor White
        Write-Host "   • Help desk integration enabled" -ForegroundColor White
        
    } catch {
        Write-Error "Standard Office deployment failed: $($_.Exception.Message)"
    }
}

# ===================================================================
# EXAMPLE 4: KIOSK/PUBLIC COMPUTER DEPLOYMENT
# ===================================================================

function Deploy-KioskEnvironment {
    <#
    .SYNOPSIS
        Deploys ReSet Toolkit for kiosk and public computers
    .DESCRIPTION
        Suitable for: Public kiosks, shared computers, libraries
        Features: Highly restricted, automatic operations
    #>
    
    Write-Host "🖥️ Deploying Kiosk Environment Configuration..." -ForegroundColor Green
    
    $kioskConfig = @{
        # Core Settings
        Enabled = $true
        RequireApproval = $true
        
        # High Security
        MaintenanceWindow = "03-04"  # Very narrow window
        DisabledOperations = "Backup,Restore"  # Only allow resets
        AllowRemoteExecution = $false
        AllowUserOverride = $false
        
        # Minimal Backup
        BackupRequired = $false  # No backup for public computers
        AutoBackup = $false
        MaxBackupDays = 7  # Minimal retention
        
        # Security Monitoring
        AuditMode = $true
        EnableEventLogging = $true
        LogLevel = "WARN"  # Only important events
        
        # Silent Operation
        EnableSilentMode = $true
        NotificationLevel = "None"  # No user notifications
        ExecutionTimeout = 15  # Quick operations only
    }
    
    try {
        # Deploy policy
        Deploy-ReSetToolkitPolicy -PolicySettings $kioskConfig -Scope Computer -Force
        
        # Setup automated reset schedule
        New-AutomatedResetSchedule -Frequency "Daily" -Time "03:30"
        
        # Configure lockdown policies
        Enable-KioskLockdown
        
        Write-Host "✅ Kiosk Environment deployment completed" -ForegroundColor Green
        Write-Host "📋 Configuration Summary:" -ForegroundColor Cyan
        Write-Host "   • Very narrow maintenance window (3-4 AM)" -ForegroundColor White
        Write-Host "   • Only reset operations allowed" -ForegroundColor White
        Write-Host "   • No backup retention" -ForegroundColor White
        Write-Host "   • Silent operation with no user notifications" -ForegroundColor White
        Write-Host "   • Automated daily reset schedule" -ForegroundColor White
        
    } catch {
        Write-Error "Kiosk deployment failed: $($_.Exception.Message)"
    }
}

# ===================================================================
# EXAMPLE 5: PILOT/TESTING DEPLOYMENT
# ===================================================================

function Deploy-PilotTesting {
    <#
    .SYNOPSIS
        Deploys ReSet Toolkit for pilot testing
    .DESCRIPTION
        Suitable for: Pilot groups, testing new configurations
        Features: Enhanced logging, feedback collection
    #>
    
    Write-Host "🧪 Deploying Pilot Testing Configuration..." -ForegroundColor Green
    
    $pilotConfig = @{
        # Core Settings
        Enabled = $true
        RequireApproval = $false
        
        # Testing-Friendly
        MaintenanceWindow = ""  # No restrictions for testing
        DisabledOperations = ""  # All operations for testing
        AllowRemoteExecution = $true
        AllowUserOverride = $true
        
        # Enhanced Backup for Testing
        BackupRequired = $true
        AutoBackup = $true
        MaxBackupDays = 60
        
        # Maximum Logging
        AuditMode = $true
        EnableEventLogging = $true
        LogLevel = "DEBUG"  # Maximum detail for pilot
        
        # Detailed User Feedback
        EnableSilentMode = $false  # Interactive for feedback
        NotificationLevel = "Verbose"
        ExecutionTimeout = 45
    }
    
    try {
        # Deploy policy
        Deploy-ReSetToolkitPolicy -PolicySettings $pilotConfig -Scope Computer -Force
        
        # Setup feedback collection
        New-PilotFeedbackSystem
        
        # Enhanced monitoring for pilot
        Enable-PilotMonitoring -ReportingInterval "Hourly"
        
        # Create pilot documentation
        New-PilotDocumentation
        
        Write-Host "✅ Pilot Testing deployment completed" -ForegroundColor Green
        Write-Host "📋 Configuration Summary:" -ForegroundColor Cyan
        Write-Host "   • No operational restrictions" -ForegroundColor White
        Write-Host "   • Maximum debug logging" -ForegroundColor White
        Write-Host "   • Interactive mode for user feedback" -ForegroundColor White
        Write-Host "   • Enhanced monitoring and reporting" -ForegroundColor White
        Write-Host "   • Feedback collection system enabled" -ForegroundColor White
        
    } catch {
        Write-Error "Pilot deployment failed: $($_.Exception.Message)"
    }
}

# ===================================================================
# EXAMPLE 6: MIXED ENVIRONMENT DEPLOYMENT
# ===================================================================

function Deploy-MixedEnvironment {
    <#
    .SYNOPSIS
        Deploys different configurations based on computer groups
    .DESCRIPTION
        Suitable for: Organizations with diverse computer roles
        Features: Role-based configuration deployment
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Servers", "Workstations", "Laptops", "Kiosks")]
        [string]$ComputerRole
    )
    
    Write-Host "🔄 Deploying Mixed Environment Configuration for $ComputerRole..." -ForegroundColor Green
    
    $configs = @{
        "Servers" = @{
            Enabled = $true
            RequireApproval = $true
            MaintenanceWindow = "02-04"
            DisabledOperations = "Cleanup"
            BackupRequired = $true
            MaxBackupDays = 365
            AuditMode = $true
            LogLevel = "INFO"
            AllowRemoteExecution = $true  # For server management
            NotificationLevel = "Minimal"
        }
        
        "Workstations" = @{
            Enabled = $true
            RequireApproval = $false
            MaintenanceWindow = "18-08"
            DisabledOperations = ""
            BackupRequired = $true
            MaxBackupDays = 90
            AuditMode = $true
            LogLevel = "INFO"
            AllowRemoteExecution = $false
            NotificationLevel = "Normal"
        }
        
        "Laptops" = @{
            Enabled = $true
            RequireApproval = $false
            MaintenanceWindow = ""  # No restrictions for mobile users
            DisabledOperations = ""
            BackupRequired = $true
            MaxBackupDays = 60  # Shorter retention for mobile
            AuditMode = $true
            LogLevel = "INFO"
            AllowRemoteExecution = $false
            NotificationLevel = "Normal"
        }
        
        "Kiosks" = @{
            Enabled = $true
            RequireApproval = $true
            MaintenanceWindow = "03-04"
            DisabledOperations = "Backup,Restore"
            BackupRequired = $false
            MaxBackupDays = 7
            AuditMode = $true
            LogLevel = "WARN"
            AllowRemoteExecution = $false
            NotificationLevel = "None"
        }
    }
    
    try {
        $config = $configs[$ComputerRole]
        
        # Deploy role-specific configuration
        Deploy-ReSetToolkitPolicy -PolicySettings $config -Scope Computer -Force
        
        # Apply role-specific customizations
        switch ($ComputerRole) {
            "Servers" {
                Enable-ServerManagement
                New-ServerMonitoringTasks
            }
            "Workstations" {
                New-UserTrainingMaterials
                Enable-HelpDeskIntegration
            }
            "Laptops" {
                Enable-OfflineSupport
                Configure-PowerManagement
            }
            "Kiosks" {
                Enable-KioskLockdown
                New-AutomatedResetSchedule -Frequency "Daily" -Time "03:30"
            }
        }
        
        Write-Host "✅ Mixed Environment deployment for $ComputerRole completed" -ForegroundColor Green
        
    } catch {
        Write-Error "Mixed Environment deployment failed: $($_.Exception.Message)"
    }
}

# ===================================================================
# HELPER FUNCTIONS
# ===================================================================

function New-ApprovalWorkflow {
    param([bool]$RequireJustification, [bool]$NotifyAdministrators)
    
    Write-Host "Creating approval workflow..." -ForegroundColor Yellow
    # Implementation would create approval process
}

function New-ComplianceMonitoring {
    param([bool]$AlertOnViolations, [string]$ReportingFrequency)
    
    Write-Host "Setting up compliance monitoring..." -ForegroundColor Yellow
    # Implementation would setup monitoring
}

function New-DevelopmentShortcuts {
    Write-Host "Creating development shortcuts..." -ForegroundColor Yellow
    # Implementation would create dev-specific shortcuts
}

function Enable-DebugLogging {
    param([string]$LogPath)
    
    Write-Host "Enabling debug logging..." -ForegroundColor Yellow
    # Implementation would configure debug logging
}

function New-UserTrainingMaterials {
    Write-Host "Creating user training materials..." -ForegroundColor Yellow
    # Implementation would generate training docs
}

function Enable-HelpDeskIntegration {
    Write-Host "Enabling help desk integration..." -ForegroundColor Yellow
    # Implementation would setup help desk hooks
}

function New-AutomatedResetSchedule {
    param([string]$Frequency, [string]$Time)
    
    Write-Host "Creating automated reset schedule..." -ForegroundColor Yellow
    # Implementation would create scheduled tasks
}

function Enable-KioskLockdown {
    Write-Host "Enabling kiosk lockdown..." -ForegroundColor Yellow
    # Implementation would apply kiosk restrictions
}

function New-PilotFeedbackSystem {
    Write-Host "Setting up pilot feedback system..." -ForegroundColor Yellow
    # Implementation would create feedback collection
}

function Enable-PilotMonitoring {
    param([string]$ReportingInterval)
    
    Write-Host "Enabling pilot monitoring..." -ForegroundColor Yellow
    # Implementation would setup enhanced monitoring
}

function New-PilotDocumentation {
    Write-Host "Creating pilot documentation..." -ForegroundColor Yellow
    # Implementation would generate pilot docs
}

function Enable-ServerManagement {
    Write-Host "Enabling server management features..." -ForegroundColor Yellow
    # Implementation would enable server-specific features
}

function New-ServerMonitoringTasks {
    Write-Host "Creating server monitoring tasks..." -ForegroundColor Yellow
    # Implementation would create server monitoring
}

function Enable-OfflineSupport {
    Write-Host "Enabling offline support..." -ForegroundColor Yellow
    # Implementation would configure offline capabilities
}

function Configure-PowerManagement {
    Write-Host "Configuring power management..." -ForegroundColor Yellow
    # Implementation would setup power management
}

# ===================================================================
# MAIN MENU
# ===================================================================

function Show-DeploymentMenu {
    Clear-Host
    Write-Host "ReSet Toolkit - GPO Deployment Examples" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select a deployment scenario:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. 🔒 Secure Enterprise (Financial/Healthcare/Government)" -ForegroundColor White
    Write-Host "2. 🛠️ Development Environment (Dev Teams/Testing)" -ForegroundColor White
    Write-Host "3. 🏢 Standard Office (General Workstations)" -ForegroundColor White
    Write-Host "4. 🖥️ Kiosk Environment (Public/Shared Computers)" -ForegroundColor White
    Write-Host "5. 🧪 Pilot Testing (Configuration Testing)" -ForegroundColor White
    Write-Host "6. 🔄 Mixed Environment (Role-Based Deployment)" -ForegroundColor White
    Write-Host "7. ❌ Exit" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1-7)"
    
    switch ($choice) {
        "1" { Deploy-SecureEnterprise }
        "2" { Deploy-DevelopmentEnvironment }
        "3" { Deploy-StandardOffice }
        "4" { Deploy-KioskEnvironment }
        "5" { Deploy-PilotTesting }
        "6" {
            Write-Host "Select computer role:" -ForegroundColor Yellow
            Write-Host "1. Servers" -ForegroundColor White
            Write-Host "2. Workstations" -ForegroundColor White
            Write-Host "3. Laptops" -ForegroundColor White
            Write-Host "4. Kiosks" -ForegroundColor White
            $roleChoice = Read-Host "Enter choice (1-4)"
            
            $roles = @("Servers", "Workstations", "Laptops", "Kiosks")
            $role = $roles[[int]$roleChoice - 1]
            Deploy-MixedEnvironment -ComputerRole $role
        }
        "7" { Write-Host "Goodbye!" -ForegroundColor Green; return }
        default { Write-Host "Invalid choice. Please try again." -ForegroundColor Red; Start-Sleep 2; Show-DeploymentMenu }
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to menu"
    Show-DeploymentMenu
}

# Run the menu if script is executed directly
if ($MyInvocation.InvocationName -ne ".") {
    Show-DeploymentMenu
}