# ===================================================================
# Windows Reset Toolkit - Utility Module (ReSetUtils.psm1)
# Author: jomardyan
# Description: Common utilities, logging, backup, and UI functions
# Version: 1.0.0
# ===================================================================

# Global Configuration
$Script:LogPath = Join-Path $PSScriptRoot "..\logs"
$Script:BackupPath = Join-Path $PSScriptRoot "..\backups"
$Script:ConfigPath = Join-Path $PSScriptRoot "..\config"

# Ensure required directories exist
foreach ($dir in @($Script:LogPath, $Script:BackupPath, $Script:ConfigPath)) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# ===================================================================
# LOGGING FUNCTIONS
# ===================================================================

function Write-ReSetLog {
    <#
    .SYNOPSIS
    Writes formatted log entries to file and console.
    
    .PARAMETER Message
    The message to log.
    
    .PARAMETER Level
    Log level: INFO, WARN, ERROR, SUCCESS.
    
    .PARAMETER NoConsole
    If specified, only writes to log file, not console.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO",
        
        [switch]$NoConsole
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Create log filename with current date
    $logFile = Join-Path $Script:LogPath "reset-operations-$(Get-Date -Format 'yyyy-MM-dd').log"
    
    # Write to log file
    try {
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to write to log file: $_"
    }
    
    # Write to console with colors if not suppressed
    if (-not $NoConsole) {
        switch ($Level) {
            "INFO"    { Write-Host $logEntry -ForegroundColor Cyan }
            "WARN"    { Write-Host $logEntry -ForegroundColor Yellow }
            "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
            "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        }
    }
}

function Start-ReSetOperation {
    <#
    .SYNOPSIS
    Starts a new reset operation with logging.
    
    .PARAMETER OperationName
    Name of the operation being started.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationName
    )
    
    Write-ReSetLog "═══════════════════════════════════════════════════════════════" "INFO"
    Write-ReSetLog "Starting operation: $OperationName" "INFO"
    Write-ReSetLog "User: $env:USERNAME | Computer: $env:COMPUTERNAME" "INFO"
    Write-ReSetLog "PowerShell Version: $($PSVersionTable.PSVersion)" "INFO"
    Write-ReSetLog "═══════════════════════════════════════════════════════════════" "INFO"
    
    return @{
        OperationName = $OperationName
        StartTime = Get-Date
        OperationId = [System.Guid]::NewGuid()
    }
}

function Complete-ReSetOperation {
    <#
    .SYNOPSIS
    Completes a reset operation with summary logging.
    
    .PARAMETER OperationInfo
    Operation info returned from Start-ReSetOperation.
    
    .PARAMETER Success
    Whether the operation was successful.
    
    .PARAMETER ErrorMessage
    Error message if operation failed.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$OperationInfo,
        
        [Parameter(Mandatory = $false)]
        [bool]$Success = $true,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = ""
    )
    
    $duration = (Get-Date) - $OperationInfo.StartTime
    $status = if ($Success) { "SUCCESS" } else { "ERROR" }
    
    Write-ReSetLog "═══════════════════════════════════════════════════════════════" $status
    Write-ReSetLog "Operation completed: $($OperationInfo.OperationName)" $status
    Write-ReSetLog "Duration: $($duration.ToString('mm\:ss\.fff'))" "INFO"
    Write-ReSetLog "Status: $(if ($Success) { 'SUCCESSFUL' } else { 'FAILED' })" $status
    
    if (-not $Success -and $ErrorMessage) {
        Write-ReSetLog "Error: $ErrorMessage" "ERROR"
    }
    
    Write-ReSetLog "═══════════════════════════════════════════════════════════════" $status
}

# ===================================================================
# BACKUP FUNCTIONS
# ===================================================================

function New-ReSetBackup {
    <#
    .SYNOPSIS
    Creates a backup of registry keys or files before reset operations.
    
    .PARAMETER BackupName
    Name/category for this backup.
    
    .PARAMETER RegistryPaths
    Array of registry paths to backup.
    
    .PARAMETER FilePaths
    Array of file paths to backup.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$RegistryPaths = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$FilePaths = @()
    )
    
    $backupTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $backupDir = Join-Path $Script:BackupPath "$BackupName-$backupTimestamp"
    
    try {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Write-ReSetLog "Created backup directory: $backupDir" "INFO"
        
        # Backup registry keys
        if ($RegistryPaths.Count -gt 0) {
            $regBackupDir = Join-Path $backupDir "Registry"
            New-Item -ItemType Directory -Path $regBackupDir -Force | Out-Null
            
            foreach ($regPath in $RegistryPaths) {
                try {
                    if (Test-Path $regPath) {
                        $regFileName = ($regPath -replace ':', '') -replace '\\', '_'
                        $regBackupFile = Join-Path $regBackupDir "$regFileName.reg"
                        
                        # Export registry key
                        $null = & reg export $regPath $regBackupFile /y 2>&1
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-ReSetLog "Backed up registry: $regPath" "SUCCESS"
                        } else {
                            Write-ReSetLog "Failed to backup registry: $regPath" "WARN"
                        }
                    }
                }
                catch {
                    Write-ReSetLog "Error backing up registry $regPath : $($_.Exception.Message)" "ERROR"
                }
            }
        }
        
        # Backup files
        if ($FilePaths.Count -gt 0) {
            $fileBackupDir = Join-Path $backupDir "Files"
            New-Item -ItemType Directory -Path $fileBackupDir -Force | Out-Null
            
            foreach ($filePath in $FilePaths) {
                try {
                    if (Test-Path $filePath) {
                        $fileName = Split-Path $filePath -Leaf
                        $backupFile = Join-Path $fileBackupDir $fileName
                        
                        Copy-Item -Path $filePath -Destination $backupFile -Force
                        Write-ReSetLog "Backed up file: $filePath" "SUCCESS"
                    }
                }
                catch {
                    Write-ReSetLog "Error backing up file $filePath : $($_.Exception.Message)" "ERROR"
                }
            }
        }
        
        # Create backup manifest
        $manifest = @{
            BackupName = $BackupName
            Timestamp = $backupTimestamp
            BackupPath = $backupDir
            RegistryPaths = $RegistryPaths
            FilePaths = $FilePaths
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
        }
        
        $manifestPath = Join-Path $backupDir "backup-manifest.json"
        $manifest | ConvertTo-Json -Depth 3 | Out-File -FilePath $manifestPath -Encoding UTF8
        
        Write-ReSetLog "Backup completed successfully: $backupDir" "SUCCESS"
        return $backupDir
    }
    catch {
        Write-ReSetLog "Failed to create backup: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# ===================================================================
# ADMIN AND PERMISSION FUNCTIONS
# ===================================================================

function Test-IsAdmin {
    <#
    .SYNOPSIS
    Checks if the current PowerShell session is running as Administrator.
    #>
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-AdminRights {
    <#
    .SYNOPSIS
    Ensures the script is running with administrator privileges.
    #>
    if (-not (Test-IsAdmin)) {
        Write-ReSetLog "This operation requires administrator privileges!" "ERROR"
        Write-ReSetLog "Please restart PowerShell as Administrator and try again." "ERROR"
        throw "Administrator privileges required"
    }
}

# ===================================================================
# REGISTRY FUNCTIONS
# ===================================================================

function Set-RegistryValue {
    <#
    .SYNOPSIS
    Safely sets a registry value with error handling and logging.
    
    .PARAMETER Path
    Registry path (e.g., "HKLM:\SOFTWARE\Microsoft\...")
    
    .PARAMETER Name
    Value name.
    
    .PARAMETER Value
    Value data.
    
    .PARAMETER Type
    Value type (String, DWord, QWord, etc.)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        $Value,
        
        [Parameter(Mandatory = $false)]
        [string]$Type = "String"
    )
    
    try {
        # Ensure the registry path exists
        if (!(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            Write-ReSetLog "Created registry path: $Path" "INFO"
        }
        
        # Set the registry value
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        Write-ReSetLog "Set registry value: $Path\$Name = $Value" "SUCCESS"
        return $true
    }
    catch {
        Write-ReSetLog "Failed to set registry value $Path\$Name : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Remove-RegistryValue {
    <#
    .SYNOPSIS
    Safely removes a registry value with error handling and logging.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    try {
        if (Test-Path $Path) {
            $property = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($property) {
                Remove-ItemProperty -Path $Path -Name $Name -Force
                Write-ReSetLog "Removed registry value: $Path\$Name" "SUCCESS"
                return $true
            }
        }
        Write-ReSetLog "Registry value not found: $Path\$Name" "WARN"
        return $true
    }
    catch {
        Write-ReSetLog "Failed to remove registry value $Path\$Name : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Remove-RegistryKey {
    <#
    .SYNOPSIS
    Safely removes a registry key with error handling and logging.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        if (Test-Path $Path) {
            Remove-Item -Path $Path -Recurse -Force
            Write-ReSetLog "Removed registry key: $Path" "SUCCESS"
            return $true
        }
        Write-ReSetLog "Registry key not found: $Path" "WARN"
        return $true
    }
    catch {
        Write-ReSetLog "Failed to remove registry key $Path : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ===================================================================
# SERVICE FUNCTIONS
# ===================================================================

function Restart-WindowsService {
    <#
    .SYNOPSIS
    Safely restarts a Windows service with error handling.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            Write-ReSetLog "Restarting service: $ServiceName" "INFO"
            
            if ($service.Status -eq 'Running') {
                Stop-Service -Name $ServiceName -Force -ErrorAction Stop
                Write-ReSetLog "Stopped service: $ServiceName" "SUCCESS"
            }
            
            Start-Service -Name $ServiceName -ErrorAction Stop
            Write-ReSetLog "Started service: $ServiceName" "SUCCESS"
            return $true
        } else {
            Write-ReSetLog "Service not found: $ServiceName" "WARN"
            return $false
        }
    }
    catch {
        Write-ReSetLog "Failed to restart service $ServiceName : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ===================================================================
# UI AND PROGRESS FUNCTIONS
# ===================================================================

function Write-ReSetHeader {
    <#
    .SYNOPSIS
    Displays a formatted header for reset operations.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )
    
    $width = 80
    $separator = "═" * $width
    
    Write-Host ""
    Write-Host $separator -ForegroundColor Cyan
    Write-Host " $Title".PadRight($width - 1) -ForegroundColor White -BackgroundColor DarkBlue
    if ($Description) {
        Write-Host " $Description".PadRight($width - 1) -ForegroundColor Gray
    }
    Write-Host $separator -ForegroundColor Cyan
    Write-Host ""
}

function Write-ProgressStep {
    <#
    .SYNOPSIS
    Displays progress information for reset steps.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        
        [Parameter(Mandatory = $false)]
        [int]$CurrentStep = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$TotalSteps = 1
    )
    
    $percent = [math]::Round(($CurrentStep / $TotalSteps) * 100)
    Write-Progress -Activity "Windows Reset Operation" -Status $StepName -PercentComplete $percent
    Write-ReSetLog "[$CurrentStep/$TotalSteps] $StepName" "INFO"
}

function Show-ReSetMenu {
    <#
    .SYNOPSIS
    Displays an interactive menu for script selection.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$MenuItems,
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "Windows Reset Toolkit"
    )
    
    Clear-Host
    Write-ReSetHeader -Title $Title -Description "Select reset operation to perform"
    
    $options = @()
    $index = 1
    
    foreach ($key in $MenuItems.Keys | Sort-Object) {
        $description = $MenuItems[$key]
        Write-Host " [$index] " -ForegroundColor Yellow -NoNewline
        Write-Host $key -ForegroundColor White -NoNewline
        Write-Host " - $description" -ForegroundColor Gray
        $options += $key
        $index++
    }
    
    Write-Host ""
    Write-Host " [0] Exit" -ForegroundColor Red
    Write-Host ""
    
    do {
        $choice = Read-Host "Enter your choice (0-$($options.Count))"
        
        if ($choice -eq "0") {
            return $null
        }
        
        try {
            $choiceInt = [int]$choice
            if ($choiceInt -ge 1 -and $choiceInt -le $options.Count) {
                return $options[$choiceInt - 1]
            }
        }
        catch {
            # Invalid input, continue loop
        }
        
        Write-Host "Invalid choice. Please enter a number between 0 and $($options.Count)." -ForegroundColor Red
    } while ($true)
}

# ===================================================================
# VALIDATION FUNCTIONS
# ===================================================================

function Test-WindowsVersion {
    <#
    .SYNOPSIS
    Validates that the system is running Windows 10 or 11.
    #>
    $version = [System.Environment]::OSVersion.Version
    $isWindows10Plus = $version.Major -ge 10
    
    if (-not $isWindows10Plus) {
        Write-ReSetLog "This toolkit requires Windows 10 or later. Current version: $($version.ToString())" "ERROR"
        return $false
    }
    
    return $true
}

function Confirm-ReSetOperation {
    <#
    .SYNOPSIS
    Prompts user to confirm a potentially destructive operation.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationName,
        
        [Parameter(Mandatory = $false)]
        [string]$Warning = "This operation will reset system settings to defaults."
    )
    
    Write-Host ""
    Write-Host "⚠️  WARNING: $Warning" -ForegroundColor Yellow
    Write-Host "Operation: $OperationName" -ForegroundColor Cyan
    Write-Host ""
    
    do {
        $response = Read-Host "Do you want to continue? (y/n)"
        switch ($response.ToLower()) {
            'y' { return $true }
            'yes' { return $true }
            'n' { return $false }
            'no' { return $false }
            default { 
                Write-Host "Please enter 'y' for yes or 'n' for no." -ForegroundColor Red 
            }
        }
    } while ($true)
}

# ===================================================================
# EXPORT MODULE MEMBERS
# ===================================================================

Export-ModuleMember -Function @(
    'Write-ReSetLog',
    'Start-ReSetOperation',
    'Complete-ReSetOperation',
    'New-ReSetBackup',
    'Test-IsAdmin',
    'Assert-AdminRights',
    'Set-RegistryValue',
    'Remove-RegistryValue',
    'Remove-RegistryKey',
    'Restart-WindowsService',
    'Write-ReSetHeader',
    'Write-ProgressStep',
    'Show-ReSetMenu',
    'Test-WindowsVersion',
    'Confirm-ReSetOperation'
)