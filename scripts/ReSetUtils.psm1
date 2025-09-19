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
$Script:TempPath = Join-Path $PSScriptRoot "..\temp"
$Script:ReportsPath = Join-Path $PSScriptRoot "..\reports"

# Enhanced configuration
$Script:Config = @{
    MaxLogFiles = 30
    MaxBackupDays = 90
    CompressionEnabled = $true
    EncryptionEnabled = $false
    DetailedLogging = $true
    PerformanceMetrics = $true
    ADIntegration = $true
    RemoteExecution = $false
}

# Ensure required directories exist
foreach ($dir in @($Script:LogPath, $Script:BackupPath, $Script:ConfigPath, $Script:TempPath, $Script:ReportsPath)) {
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
    [CmdletBinding(SupportsShouldProcess)]
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
    
    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set registry value to '$Value'")) {
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
    } else {
        Write-ReSetLog "Registry value change cancelled by user: $Path\$Name" "INFO"
        return $false
    }
}

function Remove-RegistryValue {
    <#
    .SYNOPSIS
    Safely removes a registry value with error handling and logging.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Remove registry value")) {
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
    } else {
        Write-ReSetLog "Registry value removal cancelled by user: $Path\$Name" "INFO"
        return $false
    }
}

function Remove-RegistryKey {
    <#
    .SYNOPSIS
    Safely removes a registry key with error handling and logging.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    if ($PSCmdlet.ShouldProcess($Path, "Remove registry key and all subkeys")) {
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
    } else {
        Write-ReSetLog "Registry key removal cancelled by user: $Path" "INFO"
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
# ENHANCED SYSTEM FUNCTIONS
# ===================================================================

function Get-SystemHealth {
    <#
    .SYNOPSIS
        Performs comprehensive system health check
    #>
    [CmdletBinding()]
    param()
    
    $health = @{
        SystemFiles = $null
        RegistryHealth = $null
        DiskHealth = $null
        ServiceHealth = $null
        NetworkHealth = $null
        MemoryHealth = $null
        PerformanceCounters = $null
        Timestamp = Get-Date
    }
    
    try {
        # System File Check
        Write-Host "Checking system files..." -ForegroundColor Yellow
        $sfcResult = & sfc /verifyonly 2>&1
        $health.SystemFiles = if ($LASTEXITCODE -eq 0) { 'Healthy' } else { "Issues Found: $($sfcResult -join ' ')" }
        
        # Registry Health
        Write-Host "Checking registry integrity..." -ForegroundColor Yellow
        $regKeys = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion',
            'HKLM:\SYSTEM\CurrentControlSet\Control',
            'HKLM:\SOFTWARE\Policies'
        )
        $regIssues = 0
        foreach ($key in $regKeys) {
            try {
                Get-ItemProperty -Path $key -ErrorAction Stop | Out-Null
            } catch {
                $regIssues++
            }
        }
        $health.RegistryHealth = if ($regIssues -eq 0) { 'Healthy' } else { "$regIssues Issues" }
        
        # Disk Health
        Write-Host "Checking disk health..." -ForegroundColor Yellow
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $diskIssues = @()
        foreach ($disk in $disks) {
            $freePercent = ($disk.FreeSpace / $disk.Size) * 100
            if ($freePercent -lt 10) {
                $diskIssues += "Drive $($disk.DeviceID) low space ($([math]::Round($freePercent, 2))%)"
            }
        }
        $health.DiskHealth = if ($diskIssues.Count -eq 0) { 'Healthy' } else { $diskIssues -join '; ' }
        
        # Service Health
        Write-Host "Checking critical services..." -ForegroundColor Yellow
        $criticalServices = @('Winmgmt', 'RpcSs', 'Themes', 'AudioSrv', 'Spooler')
        $serviceIssues = @()
        foreach ($service in $criticalServices) {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if (-not $svc -or $svc.Status -ne 'Running') {
                $serviceIssues += $service
            }
        }
        $health.ServiceHealth = if ($serviceIssues.Count -eq 0) { 'Healthy' } else { "Issues: $($serviceIssues -join ', ')" }
        
        # Network Health
        Write-Host "Checking network connectivity..." -ForegroundColor Yellow
        $networkTests = @(
            @{ Target = '8.8.8.8'; Type = 'Ping' },
            @{ Target = 'microsoft.com'; Type = 'DNS' }
        )
        $networkIssues = @()
        foreach ($test in $networkTests) {
            try {
                if ($test.Type -eq 'Ping') {
                    $result = Test-Connection -ComputerName $test.Target -Count 1 -Quiet
                    if (-not $result) { $networkIssues += "Ping to $($test.Target) failed" }
                } elseif ($test.Type -eq 'DNS') {
                    $result = Resolve-DnsName -Name $test.Target -ErrorAction Stop
                    if (-not $result) { $networkIssues += "DNS resolution for $($test.Target) failed" }
                }
            } catch {
                $networkIssues += "$($test.Type) test for $($test.Target) failed"
            }
        }
        $health.NetworkHealth = if ($networkIssues.Count -eq 0) { 'Healthy' } else { $networkIssues -join '; ' }
        
        # Memory Health
        Write-Host "Checking memory usage..." -ForegroundColor Yellow
        $memory = Get-ComputerInfo
        $memoryUsedPercent = (($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100
        $health.MemoryHealth = if ($memoryUsedPercent -lt 90) { 'Healthy' } else { "High usage ($([math]::Round($memoryUsedPercent, 2))%)" }
        
        # Performance Counters
        if ($Script:Config.PerformanceMetrics) {
            Write-Host "Collecting performance metrics..." -ForegroundColor Yellow
            $health.PerformanceCounters = @{
                CPUUsage = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3 | 
                           Select-Object -ExpandProperty CounterSamples | 
                           Measure-Object -Property CookedValue -Average).Average
                AvailableMemoryMB = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
                DiskQueueLength = (Get-Counter '\PhysicalDisk(_Total)\Current Disk Queue Length').CounterSamples.CookedValue
            }
        }
        
    } catch {
        Write-Warning "Error during system health check: $($_.Exception.Message)"
    }
    
    return $health
}

function Invoke-AdvancedCleanup {
    <#
    .SYNOPSIS
        Performs advanced system cleanup operations
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$IncludeTempFiles,
        
        [Parameter()]
        [switch]$IncludeEventLogs,
        
        [Parameter()]
        [switch]$IncludeRecycleBin,
        
        [Parameter()]
        [switch]$IncludePrefetch,
        
        [Parameter()]
        [switch]$IncludeWindowsUpdate,
        
        [Parameter()]
        [switch]$IncludeBrowserCache
    )
    
    $cleanupResults = @{}
    
    try {
        if ($IncludeTempFiles) {
            Write-Host "Cleaning temporary files..." -ForegroundColor Yellow
            $tempPaths = @(
                $env:TEMP,
                "$env:WINDIR\Temp",
                "$env:LOCALAPPDATA\Temp"
            )
            
            $totalDeleted = 0
            foreach ($path in $tempPaths) {
                if (Test-Path $path) {
                    $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue
                    $fileCount = $files.Count
                    $files | Remove-Item -Force -ErrorAction SilentlyContinue
                    $totalDeleted += $fileCount
                }
            }
            $cleanupResults.TempFiles = "$totalDeleted files deleted"
        }
        
        if ($IncludeEventLogs) {
            Write-Host "Clearing event logs..." -ForegroundColor Yellow
            $logs = Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 0 -and $_.LogName -notmatch 'Security|System|Application' }
            $clearedCount = 0
            foreach ($log in $logs) {
                try {
                    Clear-WinEvent -LogName $log.LogName -ErrorAction SilentlyContinue
                    $clearedCount++
                } catch {
                    # Ignore errors for logs that cannot be cleared
                }
            }
            $cleanupResults.EventLogs = "$clearedCount logs cleared"
        }
        
        if ($IncludeRecycleBin) {
            Write-Host "Emptying recycle bin..." -ForegroundColor Yellow
            try {
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue
                $cleanupResults.RecycleBin = "Emptied successfully"
            } catch {
                $cleanupResults.RecycleBin = "Failed to empty"
            }
        }
        
        if ($IncludePrefetch) {
            Write-Host "Clearing prefetch files..." -ForegroundColor Yellow
            $prefetchPath = "$env:WINDIR\Prefetch"
            if (Test-Path $prefetchPath) {
                $files = Get-ChildItem -Path $prefetchPath -File -ErrorAction SilentlyContinue
                $fileCount = $files.Count
                $files | Remove-Item -Force -ErrorAction SilentlyContinue
                $cleanupResults.Prefetch = "$fileCount prefetch files deleted"
            }
        }
        
        if ($IncludeWindowsUpdate) {
            Write-Host "Clearing Windows Update cache..." -ForegroundColor Yellow
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            $updatePath = "$env:WINDIR\SoftwareDistribution\Download"
            if (Test-Path $updatePath) {
                $files = Get-ChildItem -Path $updatePath -Recurse -ErrorAction SilentlyContinue
                $fileCount = $files.Count
                $files | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                $cleanupResults.WindowsUpdate = "$fileCount update files deleted"
            }
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        }
        
        if ($IncludeBrowserCache) {
            Write-Host "Clearing browser caches..." -ForegroundColor Yellow
            $browserPaths = @(
                "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
                "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
                "$env:APPDATA\Mozilla\Firefox\Profiles\*\cache2"
            )
            
            $totalDeleted = 0
            foreach ($path in $browserPaths) {
                $resolvedPaths = Resolve-Path $path -ErrorAction SilentlyContinue
                foreach ($resolvedPath in $resolvedPaths) {
                    if (Test-Path $resolvedPath) {
                        $files = Get-ChildItem -Path $resolvedPath -Recurse -File -ErrorAction SilentlyContinue
                        $fileCount = $files.Count
                        $files | Remove-Item -Force -ErrorAction SilentlyContinue
                        $totalDeleted += $fileCount
                    }
                }
            }
            $cleanupResults.BrowserCache = "$totalDeleted cache files deleted"
        }
        
    } catch {
        Write-Warning "Error during advanced cleanup: $($_.Exception.Message)"
    }
    
    return $cleanupResults
}

function Test-ActiveDirectoryConnectivity {
    <#
    .SYNOPSIS
        Tests Active Directory connectivity and domain status
    #>
    [CmdletBinding()]
    param()
    
    if (-not $Script:Config.ADIntegration) {
        return @{ Status = 'Disabled'; Message = 'AD Integration is disabled in configuration' }
    }
    
    try {
        # Check if machine is domain joined
        $computerSystem = Get-ComputerInfo
        if ($computerSystem.PartOfDomain) {
            $domainName = $computerSystem.Domain
            
            # Test domain controller connectivity
            try {
                $dc = Get-ADDomainController -Service PrimaryDC -ErrorAction Stop
                $dcTest = Test-Connection -ComputerName $dc.HostName -Count 1 -Quiet
                
                if ($dcTest) {
                    return @{
                        Status = 'Connected'
                        Domain = $domainName
                        DomainController = $dc.HostName
                        Message = 'Successfully connected to domain'
                    }
                } else {
                    return @{
                        Status = 'Disconnected'
                        Domain = $domainName
                        Message = 'Cannot reach domain controller'
                    }
                }
            } catch {
                return @{
                    Status = 'Error'
                    Domain = $domainName
                    Message = "AD module not available or access denied: $($_.Exception.Message)"
                }
            }
        } else {
            return @{
                Status = 'Workgroup'
                Message = 'Computer is not domain joined'
            }
        }
    } catch {
        return @{
            Status = 'Error'
            Message = "Failed to check domain status: $($_.Exception.Message)"
        }
    }
}

function Reset-ActiveDirectoryCache {
    <#
    .SYNOPSIS
        Resets Active Directory cached credentials and tickets
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$ClearKerberosTickets,
        
        [Parameter()]
        [switch]$ClearCredentialCache,
        
        [Parameter()]
        [switch]$FlushDNSCache
    )
    
    $results = @{}
    
    try {
        if ($ClearKerberosTickets) {
            Write-Host "Clearing Kerberos tickets..." -ForegroundColor Yellow
            try {
                & klist purge 2>&1 | Out-Null
                $results.KerberosTickets = "Cleared successfully"
            } catch {
                $results.KerberosTickets = "Failed to clear: $($_.Exception.Message)"
            }
        }
        
        if ($ClearCredentialCache) {
            Write-Host "Clearing credential cache..." -ForegroundColor Yellow
            try {
                & cmdkey /list 2>&1 | ForEach-Object {
                    if ($_ -match "Target: (.+)") {
                        $target = $matches[1]
                        & cmdkey /delete:$target 2>&1 | Out-Null
                    }
                }
                $results.CredentialCache = "Cleared successfully"
            } catch {
                $results.CredentialCache = "Failed to clear: $($_.Exception.Message)"
            }
        }
        
        if ($FlushDNSCache) {
            Write-Host "Flushing DNS cache..." -ForegroundColor Yellow
            try {
                & ipconfig /flushdns 2>&1 | Out-Null
                $results.DNSCache = "Flushed successfully"
            } catch {
                $results.DNSCache = "Failed to flush: $($_.Exception.Message)"
            }
        }
        
        # Restart Netlogon service if AD operations were performed
        if ($ClearKerberosTickets -or $ClearCredentialCache) {
            try {
                Restart-Service -Name Netlogon -Force -ErrorAction SilentlyContinue
                $results.NetlogonService = "Restarted successfully"
            } catch {
                $results.NetlogonService = "Failed to restart: $($_.Exception.Message)"
            }
        }
        
    } catch {
        Write-Warning "Error during AD cache reset: $($_.Exception.Message)"
    }
    
    return $results
}

function New-CompressedBackup {
    <#
    .SYNOPSIS
        Creates compressed backup with optional encryption
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupName,
        
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter()]
        [switch]$Encrypt,
        
        [Parameter()]
        [SecureString]$Password
    )
    
    if (-not $Script:Config.CompressionEnabled) {
        return New-ReSetBackup -BackupName $BackupName -FilePaths @($SourcePath)
    }
    
    try {
        $backupTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $archiveName = "$BackupName-$backupTimestamp.zip"
        $archivePath = Join-Path $Script:BackupPath $archiveName
        
        # Create compressed archive
        if ($PSVersionTable.PSVersion.Major -ge 5) {
            Compress-Archive -Path $SourcePath -DestinationPath $archivePath -CompressionLevel Optimal
        } else {
            # Fallback for older PowerShell versions
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::CreateFromDirectory($SourcePath, $archivePath)
        }
        
        Write-ReSetLog "Created compressed backup: $archivePath" "SUCCESS"
        
        if ($Encrypt -and $Password) {
            # Note: Encryption feature placeholder - implement with proper encryption libraries in production
            Write-ReSetLog "Backup encryption requested but not implemented in this version" "WARN"
            Write-Host "Warning: Backup encryption is not implemented in this version" -ForegroundColor Yellow
        }
        
        return $archivePath
    } catch {
        Write-ReSetLog "Failed to create compressed backup: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Restore-ReSetBackup {
    <#
    .SYNOPSIS
        Restores a previously created backup
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupName,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$Verify
    )
    
    try {
        # Find the most recent backup for the specified name
        $backupPattern = "$BackupName-*"
        $backupFiles = Get-ChildItem -Path $Script:BackupPath -Filter "$backupPattern*" | Sort-Object LastWriteTime -Descending
        
        if (-not $backupFiles) {
            throw "No backup found for '$BackupName'"
        }
        
        $latestBackup = $backupFiles[0]
        Write-ReSetLog "Found backup: $($latestBackup.FullName)" "INFO"
        
        # Check if it's a compressed backup
        if ($latestBackup.Extension -eq '.zip') {
            return Restore-CompressedBackup -BackupPath $latestBackup.FullName -Force:$Force -Verify:$Verify
        }
        
        # Read backup manifest
        $manifestPath = "$($latestBackup.FullName).manifest"
        if (-not (Test-Path $manifestPath)) {
            throw "Backup manifest not found: $manifestPath"
        }
        
        $manifest = Get-Content $manifestPath | ConvertFrom-Json
        
        if (-not $Force) {
            Write-Host "Backup Details:" -ForegroundColor Yellow
            Write-Host "  Name: $($manifest.BackupName)" -ForegroundColor White
            Write-Host "  Date: $($manifest.Timestamp)" -ForegroundColor White
            Write-Host "  Items: $($manifest.BackupItems.Count)" -ForegroundColor White
            
            $confirm = Read-Host "Do you want to restore this backup? (y/N)"
            if ($confirm.ToLower() -ne 'y') {
                Write-Host "Restore cancelled" -ForegroundColor Yellow
                return
            }
        }
        
        Write-ReSetLog "Starting restore of backup: $BackupName" "INFO"
        
        # Restore registry items
        foreach ($item in $manifest.BackupItems) {
            if ($item.Type -eq "Registry") {
                try {
                    Write-Host "Restoring registry: $($item.Path)" -ForegroundColor Yellow
                    & reg import $item.BackupPath 2>&1 | Out-Null
                    Write-ReSetLog "Restored registry: $($item.Path)" "SUCCESS"
                } catch {
                    Write-ReSetLog "Failed to restore registry $($item.Path): $($_.Exception.Message)" "ERROR"
                }
            }
            elseif ($item.Type -eq "File") {
                try {
                    Write-Host "Restoring file: $($item.Path)" -ForegroundColor Yellow
                    Copy-Item -Path $item.BackupPath -Destination $item.Path -Force
                    Write-ReSetLog "Restored file: $($item.Path)" "SUCCESS"
                } catch {
                    Write-ReSetLog "Failed to restore file $($item.Path): $($_.Exception.Message)" "ERROR"
                }
            }
        }
        
        Write-ReSetLog "Backup restore completed: $BackupName" "SUCCESS"
        
        if ($Verify) {
            Write-Host "Verifying restore..." -ForegroundColor Yellow
            $errors = 0
            
            foreach ($item in $manifest.BackupItems) {
                if ($item.Type -eq "Registry") {
                    if (-not (Test-Path "Registry::$($item.Path)")) {
                        Write-Host "Verification failed: Registry path not found: $($item.Path)" -ForegroundColor Red
                        $errors++
                    }
                }
                elseif ($item.Type -eq "File") {
                    if (-not (Test-Path $item.Path)) {
                        Write-Host "Verification failed: File not found: $($item.Path)" -ForegroundColor Red
                        $errors++
                    }
                }
            }
            
            if ($errors -eq 0) {
                Write-Host "Restore verification: PASSED" -ForegroundColor Green
            } else {
                Write-Host "Restore verification: FAILED ($errors errors)" -ForegroundColor Red
            }
        }
        
    } catch {
        Write-ReSetLog "Error restoring backup: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Get-ReSetBackupList {
    <#
    .SYNOPSIS
        Lists all available backups
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$BackupName
    )
    
    try {
        $pattern = if ($BackupName) { "$BackupName-*" } else { "*" }
        $backupFiles = Get-ChildItem -Path $Script:BackupPath -Filter $pattern | Where-Object { $_.Name -notmatch '\.(manifest|log)$' }
        
        $backups = @()
        
        foreach ($backupFile in $backupFiles) {
            $manifestPath = "$($backupFile.FullName).manifest"
            
            if (Test-Path $manifestPath) {
                try {
                    $manifest = Get-Content $manifestPath | ConvertFrom-Json
                    $backups += [PSCustomObject]@{
                        Name = $manifest.BackupName
                        Timestamp = $manifest.Timestamp
                        Size = "$([math]::Round($backupFile.Length / 1MB, 2)) MB"
                        Items = $manifest.BackupItems.Count
                        Type = if ($backupFile.Extension -eq '.zip') { 'Compressed' } else { 'Standard' }
                        Path = $backupFile.FullName
                    }
                } catch {
                    # Handle corrupted manifests
                    $backups += [PSCustomObject]@{
                        Name = $backupFile.BaseName
                        Timestamp = $backupFile.LastWriteTime
                        Size = "$([math]::Round($backupFile.Length / 1MB, 2)) MB"
                        Items = "Unknown"
                        Type = "Unknown"
                        Path = $backupFile.FullName
                    }
                }
            }
        }
        
        return $backups | Sort-Object Timestamp -Descending
        
    } catch {
        Write-ReSetLog "Error listing backups: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Remove-ReSetBackup {
    <#
    .SYNOPSIS
        Removes old backups based on retention policy
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$RetentionDays = 30,
        
        [Parameter()]
        [string]$BackupName,
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        $pattern = if ($BackupName) { "$BackupName-*" } else { "*" }
        
        $oldBackups = Get-ChildItem -Path $Script:BackupPath -Filter $pattern | Where-Object { 
            $_.LastWriteTime -lt $cutoffDate -and $_.Name -notmatch '\.(manifest|log)$' 
        }
        
        if (-not $oldBackups) {
            Write-Host "No old backups found for cleanup" -ForegroundColor Green
            return
        }
        
        Write-Host "Found $($oldBackups.Count) backup(s) older than $RetentionDays days" -ForegroundColor Yellow
        
        if (-not $Force) {
            foreach ($backup in $oldBackups) {
                Write-Host "  $($backup.Name) - $($backup.LastWriteTime)" -ForegroundColor Gray
            }
            
            $confirm = Read-Host "Delete these backups? (y/N)"
            if ($confirm.ToLower() -ne 'y') {
                Write-Host "Cleanup cancelled" -ForegroundColor Yellow
                return
            }
        }
        
        $deletedCount = 0
        foreach ($backup in $oldBackups) {
            try {
                # Remove backup file
                Remove-Item -Path $backup.FullName -Force
                
                # Remove associated manifest
                $manifestPath = "$($backup.FullName).manifest"
                if (Test-Path $manifestPath) {
                    Remove-Item -Path $manifestPath -Force
                }
                
                Write-ReSetLog "Deleted old backup: $($backup.Name)" "INFO"
                $deletedCount++
            } catch {
                Write-ReSetLog "Failed to delete backup $($backup.Name): $($_.Exception.Message)" "ERROR"
            }
        }
        
        Write-Host "Deleted $deletedCount backup(s)" -ForegroundColor Green
        
    } catch {
        Write-ReSetLog "Error during backup cleanup: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Test-ReSetBackup {
    <#
    .SYNOPSIS
        Verifies backup integrity
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupName
    )
    
    try {
        # Find the backup
        $backupPattern = "$BackupName-*"
        $backupFiles = Get-ChildItem -Path $Script:BackupPath -Filter "$backupPattern*" | Sort-Object LastWriteTime -Descending
        
        if (-not $backupFiles) {
            throw "No backup found for '$BackupName'"
        }
        
        $latestBackup = $backupFiles[0]
        Write-Host "Testing backup: $($latestBackup.Name)" -ForegroundColor Yellow
        
        # Check if it's a compressed backup
        if ($latestBackup.Extension -eq '.zip') {
            try {
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $archive = [System.IO.Compression.ZipFile]::OpenRead($latestBackup.FullName)
                $archive.Dispose()
                Write-Host "Compressed backup integrity: OK" -ForegroundColor Green
                return $true
            } catch {
                Write-Host "Compressed backup integrity: FAILED" -ForegroundColor Red
                return $false
            }
        }
        
        # Check manifest
        $manifestPath = "$($latestBackup.FullName).manifest"
        if (-not (Test-Path $manifestPath)) {
            Write-Host "Backup manifest: MISSING" -ForegroundColor Red
            return $false
        }
        
        try {
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
            Write-Host "Backup manifest: OK" -ForegroundColor Green
        } catch {
            Write-Host "Backup manifest: CORRUPTED" -ForegroundColor Red
            return $false
        }
        
        # Check backup items
        $missingItems = 0
        foreach ($item in $manifest.BackupItems) {
            if (-not (Test-Path $item.BackupPath)) {
                Write-Host "Missing backup item: $($item.BackupPath)" -ForegroundColor Red
                $missingItems++
            }
        }
        
        if ($missingItems -eq 0) {
            Write-Host "Backup integrity: PASSED" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Backup integrity: FAILED ($missingItems missing items)" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-ReSetLog "Error testing backup: $($_.Exception.Message)" "ERROR"
        Write-Host "Backup test: ERROR" -ForegroundColor Red
        return $false
    }
}

function Export-ReSetBackup {
    <#
    .SYNOPSIS
        Exports backup to external location
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupName,
        
        [Parameter(Mandatory = $true)]
        [string]$ExportPath,
        
        [Parameter()]
        [switch]$Compress
    )
    
    try {
        if (-not (Test-Path $ExportPath)) {
            New-Item -ItemType Directory -Path $ExportPath -Force | Out-Null
        }
        
        # Find the backup
        $backupPattern = "$BackupName-*"
        $backupFiles = Get-ChildItem -Path $Script:BackupPath -Filter "$backupPattern*" | Sort-Object LastWriteTime -Descending
        
        if (-not $backupFiles) {
            throw "No backup found for '$BackupName'"
        }
        
        $latestBackup = $backupFiles[0]
        $exportName = "$BackupName-Export-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
        
        if ($Compress) {
            $exportFilePath = Join-Path $ExportPath "$exportName.zip"
            $tempExportDir = Join-Path $Script:TempPath $exportName
            
            # Create temporary directory
            New-Item -ItemType Directory -Path $tempExportDir -Force | Out-Null
            
            # Copy backup files to temp directory
            Copy-Item -Path $latestBackup.FullName -Destination $tempExportDir -Force
            $manifestPath = "$($latestBackup.FullName).manifest"
            if (Test-Path $manifestPath) {
                Copy-Item -Path $manifestPath -Destination $tempExportDir -Force
            }
            
            # Create compressed export
            Compress-Archive -Path "$tempExportDir\*" -DestinationPath $exportFilePath -CompressionLevel Optimal
            
            # Cleanup temp directory
            Remove-Item -Path $tempExportDir -Recurse -Force
            
            Write-Host "Backup exported (compressed): $exportFilePath" -ForegroundColor Green
        } else {
            $exportDir = Join-Path $ExportPath $exportName
            New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
            
            # Copy backup files
            Copy-Item -Path $latestBackup.FullName -Destination $exportDir -Force
            $manifestPath = "$($latestBackup.FullName).manifest"
            if (Test-Path $manifestPath) {
                Copy-Item -Path $manifestPath -Destination $exportDir -Force
            }
            
            Write-Host "Backup exported: $exportDir" -ForegroundColor Green
        }
        
    } catch {
        Write-ReSetLog "Error exporting backup: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Invoke-SystemReport {
    <#
    .SYNOPSIS
        Generates comprehensive system report
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ReportPath
    )
    
    if (-not $ReportPath) {
        $ReportPath = Join-Path $Script:ReportsPath "SystemReport-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').html"
    }
    
    try {
        $systemInfo = @{
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            OSVersion = [System.Environment]::OSVersion.VersionString
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            Domain = (Get-ComputerInfo
            LastBootTime = (Get-ComputerInfo
            TotalRAM = [math]::Round((Get-ComputerInfo
            SystemHealth = Get-SystemHealth
            ADStatus = Test-ActiveDirectoryConnectivity
            Timestamp = Get-Date
        }
        
        # Create HTML report
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows System Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0078d4; }
        h2 { color: #323130; border-bottom: 1px solid #edebe9; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .healthy { color: green; }
        .warning { color: orange; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>Windows System Report</h1>
    <p>Generated: $($systemInfo.Timestamp)</p>
    
    <h2>System Information</h2>
    <table>
        <tr><th>Property</th><th>Value</th></tr>
        <tr><td>Computer Name</td><td>$($systemInfo.ComputerName)</td></tr>
        <tr><td>User Name</td><td>$($systemInfo.UserName)</td></tr>
        <tr><td>OS Version</td><td>$($systemInfo.OSVersion)</td></tr>
        <tr><td>PowerShell Version</td><td>$($systemInfo.PowerShellVersion)</td></tr>
        <tr><td>Domain</td><td>$($systemInfo.Domain)</td></tr>
        <tr><td>Last Boot Time</td><td>$($systemInfo.LastBootTime)</td></tr>
        <tr><td>Total RAM (GB)</td><td>$($systemInfo.TotalRAM)</td></tr>
    </table>
    
    <h2>System Health</h2>
    <table>
        <tr><th>Component</th><th>Status</th></tr>
        <tr><td>System Files</td><td class="$(if($systemInfo.SystemHealth.SystemFiles -eq 'Healthy'){'healthy'}else{'error'})">$($systemInfo.SystemHealth.SystemFiles)</td></tr>
        <tr><td>Registry Health</td><td class="$(if($systemInfo.SystemHealth.RegistryHealth -eq 'Healthy'){'healthy'}else{'warning'})">$($systemInfo.SystemHealth.RegistryHealth)</td></tr>
        <tr><td>Disk Health</td><td class="$(if($systemInfo.SystemHealth.DiskHealth -eq 'Healthy'){'healthy'}else{'warning'})">$($systemInfo.SystemHealth.DiskHealth)</td></tr>
        <tr><td>Service Health</td><td class="$(if($systemInfo.SystemHealth.ServiceHealth -eq 'Healthy'){'healthy'}else{'warning'})">$($systemInfo.SystemHealth.ServiceHealth)</td></tr>
        <tr><td>Network Health</td><td class="$(if($systemInfo.SystemHealth.NetworkHealth -eq 'Healthy'){'healthy'}else{'error'})">$($systemInfo.SystemHealth.NetworkHealth)</td></tr>
        <tr><td>Memory Health</td><td class="$(if($systemInfo.SystemHealth.MemoryHealth -eq 'Healthy'){'healthy'}else{'warning'})">$($systemInfo.SystemHealth.MemoryHealth)</td></tr>
    </table>
    
    <h2>Active Directory Status</h2>
    <table>
        <tr><th>Property</th><th>Value</th></tr>
        <tr><td>Status</td><td class="$(if($systemInfo.ADStatus.Status -eq 'Connected'){'healthy'}elseif($systemInfo.ADStatus.Status -eq 'Workgroup'){'warning'}else{'error'})">$($systemInfo.ADStatus.Status)</td></tr>
        <tr><td>Message</td><td>$($systemInfo.ADStatus.Message)</td></tr>
    </table>
</body>
</html>
"@
        
        $html | Out-File -FilePath $ReportPath -Encoding UTF8
        Write-ReSetLog "System report generated: $ReportPath" "SUCCESS"
        return $ReportPath
    } catch {
        Write-ReSetLog "Failed to generate system report: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# ===================================================================
# GROUP POLICY INTEGRATION FUNCTIONS
# ===================================================================

function Test-GroupPolicyCompliance {
    <#
    .SYNOPSIS
        Tests if the current environment complies with Group Policy settings
    .DESCRIPTION
        Checks Group Policy settings to determine if ReSet operations are allowed
    .PARAMETER OperationType
        Type of operation to check compliance for
    .PARAMETER PolicyScope
        Scope of policy to check (Computer, User, or Both)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Reset", "Backup", "Restore", "Cleanup", "All")]
        [string]$OperationType,
        
        [Parameter()]
        [ValidateSet("Computer", "User", "Both")]
        [string]$PolicyScope = "Both"
    )
    
    try {
        $compliance = @{
            Status = "Compliant"
            Allowed = $true
            Restrictions = @()
            PolicySource = "None"
        }
        
        # Check computer-level policies
        if ($PolicyScope -eq "Computer" -or $PolicyScope -eq "Both") {
            $computerPolicyPath = "HKLM:\SOFTWARE\Policies\ReSetToolkit"
            
            if (Test-Path $computerPolicyPath) {
                $compliance.PolicySource = "Computer Policy"
                
                # Check if operations are disabled
                $disabledOps = Get-ItemProperty -Path $computerPolicyPath -Name "DisabledOperations" -ErrorAction SilentlyContinue
                if ($disabledOps -and $disabledOps.DisabledOperations) {
                    $disabledList = $disabledOps.DisabledOperations -split ","
                    if ($disabledList -contains $OperationType -or $disabledList -contains "All") {
                        $compliance.Status = "Non-Compliant"
                        $compliance.Allowed = $false
                        $compliance.Restrictions += "Operation '$OperationType' disabled by Computer Policy"
                    }
                }
                
                # Check maintenance window
                $maintenanceWindow = Get-ItemProperty -Path $computerPolicyPath -Name "MaintenanceWindow" -ErrorAction SilentlyContinue
                if ($maintenanceWindow -and $maintenanceWindow.MaintenanceWindow) {
                    $currentHour = (Get-Date).Hour
                    $windowStart, $windowEnd = $maintenanceWindow.MaintenanceWindow -split "-"
                    
                    if ($currentHour -lt [int]$windowStart -or $currentHour -gt [int]$windowEnd) {
                        $compliance.Status = "Non-Compliant"
                        $compliance.Allowed = $false
                        $compliance.Restrictions += "Outside maintenance window ($($maintenanceWindow.MaintenanceWindow))"
                    }
                }
                
                # Check required approval
                $requireApproval = Get-ItemProperty -Path $computerPolicyPath -Name "RequireApproval" -ErrorAction SilentlyContinue
                if ($requireApproval -and $requireApproval.RequireApproval -eq 1) {
                    $approvalFile = Join-Path $Script:ConfigPath "operation-approval.txt"
                    if (-not (Test-Path $approvalFile)) {
                        $compliance.Status = "Pending"
                        $compliance.Allowed = $false
                        $compliance.Restrictions += "Operation requires administrative approval"
                    }
                }
            }
        }
        
        # Check user-level policies
        if ($PolicyScope -eq "User" -or $PolicyScope -eq "Both") {
            $userPolicyPath = "HKCU:\SOFTWARE\Policies\ReSetToolkit"
            
            if (Test-Path $userPolicyPath) {
                if ($compliance.PolicySource -eq "None") {
                    $compliance.PolicySource = "User Policy"
                } else {
                    $compliance.PolicySource = "Computer and User Policy"
                }
                
                # User policies typically have lower precedence than computer policies
                # but can add additional restrictions
                $userRestrictions = Get-ItemProperty -Path $userPolicyPath -Name "UserRestrictions" -ErrorAction SilentlyContinue
                if ($userRestrictions -and $userRestrictions.UserRestrictions) {
                    $restrictionList = $userRestrictions.UserRestrictions -split ","
                    if ($restrictionList -contains $OperationType) {
                        $compliance.Restrictions += "User policy restricts '$OperationType' operations"
                    }
                }
            }
        }
        
        Write-ReSetLog "Group Policy compliance check for '$OperationType': $($compliance.Status)" "INFO"
        return $compliance
        
    } catch {
        Write-ReSetLog "Error checking Group Policy compliance: $($_.Exception.Message)" "ERROR"
        return @{
            Status = "Error"
            Allowed = $false
            Restrictions = @("Failed to check Group Policy compliance")
            PolicySource = "Error"
        }
    }
}

function Get-GroupPolicyConfiguration {
    <#
    .SYNOPSIS
        Retrieves Group Policy configuration for ReSet Toolkit
    .DESCRIPTION
        Gets all Group Policy settings that affect ReSet Toolkit operations
    #>
    [CmdletBinding()]
    param()
    
    try {
        $config = @{
            ComputerPolicy = @{}
            UserPolicy = @{}
            EffectiveSettings = @{}
        }
        
        # Get computer policy settings
        $computerPolicyPath = "HKLM:\SOFTWARE\Policies\ReSetToolkit"
        if (Test-Path $computerPolicyPath) {
            $computerPolicy = Get-ItemProperty -Path $computerPolicyPath -ErrorAction SilentlyContinue
            $config.ComputerPolicy = @{
                Enabled = $computerPolicy.Enabled -eq 1
                DisabledOperations = $computerPolicy.DisabledOperations
                MaintenanceWindow = $computerPolicy.MaintenanceWindow
                RequireApproval = $computerPolicy.RequireApproval -eq 1
                LogLevel = $computerPolicy.LogLevel
                BackupRequired = $computerPolicy.BackupRequired -eq 1
                MaxBackupDays = $computerPolicy.MaxBackupDays
                AllowRemoteExecution = $computerPolicy.AllowRemoteExecution -eq 1
                AuditMode = $computerPolicy.AuditMode -eq 1
            }
        }
        
        # Get user policy settings
        $userPolicyPath = "HKCU:\SOFTWARE\Policies\ReSetToolkit"
        if (Test-Path $userPolicyPath) {
            $userPolicy = Get-ItemProperty -Path $userPolicyPath -ErrorAction SilentlyContinue
            $config.UserPolicy = @{
                UserRestrictions = $userPolicy.UserRestrictions
                AllowUserOverride = $userPolicy.AllowUserOverride -eq 1
                NotificationLevel = $userPolicy.NotificationLevel
            }
        }
        
        # Calculate effective settings (computer policy takes precedence)
        $config.EffectiveSettings = @{
            OperationsEnabled = $config.ComputerPolicy.Enabled -ne $false
            RequireBackup = $config.ComputerPolicy.BackupRequired -eq $true
            LogLevel = if ($config.ComputerPolicy.LogLevel) { $config.ComputerPolicy.LogLevel } else { "INFO" }
            AuditMode = $config.ComputerPolicy.AuditMode -eq $true
            MaintenanceWindowActive = -not [string]::IsNullOrEmpty($config.ComputerPolicy.MaintenanceWindow)
        }
        
        return $config
        
    } catch {
        Write-ReSetLog "Error retrieving Group Policy configuration: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Invoke-GroupPolicyRefresh {
    <#
    .SYNOPSIS
        Forces a Group Policy refresh to get latest policy settings
    .DESCRIPTION
        Refreshes Group Policy settings and updates ReSet Toolkit configuration
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("Computer", "User", "Both")]
        [string]$Target = "Both",
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        Write-ReSetLog "Refreshing Group Policy settings..." "INFO"
        
        $arguments = @("/force")
        if ($Target -eq "Computer") {
            $arguments += "/target:computer"
        } elseif ($Target -eq "User") {
            $arguments += "/target:user"
        }
        
        $process = Start-Process -FilePath "gpupdate" -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-ReSetLog "Group Policy refresh completed successfully" "SUCCESS"
            
            # Update toolkit configuration with new policy settings
            $newConfig = Get-GroupPolicyConfiguration
            Update-ToolkitConfiguration -PolicyConfiguration $newConfig
            
            return $true
        } else {
            Write-ReSetLog "Group Policy refresh failed with exit code: $($process.ExitCode)" "ERROR"
            return $false
        }
        
    } catch {
        Write-ReSetLog "Error refreshing Group Policy: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Update-ToolkitConfiguration {
    <#
    .SYNOPSIS
        Updates toolkit configuration based on Group Policy settings
    .DESCRIPTION
        Applies Group Policy settings to the toolkit's internal configuration
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$PolicyConfiguration
    )
    
    try {
        if (-not $PolicyConfiguration) {
            $PolicyConfiguration = Get-GroupPolicyConfiguration
        }
        
        $effective = $PolicyConfiguration.EffectiveSettings
        
        # Update logging configuration
        if ($effective.LogLevel) {
            $Script:Config.LogLevel = $effective.LogLevel
        }
        
        # Update backup requirements
        if ($effective.RequireBackup) {
            $Script:Config.ForceBackup = $true
        }
        
        # Update audit mode
        if ($effective.AuditMode) {
            $Script:Config.AuditMode = $true
            Write-ReSetLog "Audit mode enabled by Group Policy" "INFO"
        }
        
        # Update max backup days from policy
        if ($PolicyConfiguration.ComputerPolicy.MaxBackupDays) {
            $Script:Config.MaxBackupDays = $PolicyConfiguration.ComputerPolicy.MaxBackupDays
        }
        
        # Enable remote execution if allowed
        if ($PolicyConfiguration.ComputerPolicy.AllowRemoteExecution) {
            $Script:Config.RemoteExecution = $true
        }
        
        Write-ReSetLog "Toolkit configuration updated from Group Policy" "SUCCESS"
        
    } catch {
        Write-ReSetLog "Error updating toolkit configuration: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Write-GroupPolicyAuditLog {
    <#
    .SYNOPSIS
        Writes audit logs for Group Policy compliance tracking
    .DESCRIPTION
        Creates detailed audit logs for compliance and security monitoring
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationType,
        
        [Parameter(Mandatory = $true)]
        [string]$OperationName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Started", "Completed", "Failed", "Blocked")]
        [string]$Status,
        
        [Parameter()]
        [string]$Details,
        
        [Parameter()]
        [hashtable]$Compliance
    )
    
    try {
        $auditEntry = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Computer = $env:COMPUTERNAME
            User = $env:USERNAME
            Domain = $env:USERDOMAIN
            OperationType = $OperationType
            OperationName = $OperationName
            Status = $Status
            Compliance = $Compliance
            Details = $Details
            ProcessId = $PID
            SessionId = (Get-Process -Id $PID).SessionId
        }
        
        # Write to Windows Event Log for SIEM integration
        $eventId = switch ($Status) {
            "Started" { 1001 }
            "Completed" { 1002 }
            "Failed" { 1003 }
            "Blocked" { 1004 }
            default { 1000 }
        }
        
        $eventMessage = "ReSet Toolkit Operation: $OperationType - $OperationName | Status: $Status | User: $($auditEntry.User) | Computer: $($auditEntry.Computer)"
        if ($Details) {
            $eventMessage += " | Details: $Details"
        }
        
        # Write to Application Event Log
        try {
            Write-EventLog -LogName "Application" -Source "ReSetToolkit" -EventId $eventId -EntryType Information -Message $eventMessage
        } catch {
            # Event source might not exist, try to create it
            try {
                New-EventLog -LogName "Application" -Source "ReSetToolkit"
                Write-EventLog -LogName "Application" -Source "ReSetToolkit" -EventId $eventId -EntryType Information -Message $eventMessage
            } catch {
                # Fall back to file logging only
                Write-ReSetLog "Could not write to Event Log, using file logging only" "WARN"
            }
        }
        
        # Write to dedicated audit log file
        $auditLogPath = Join-Path $Script:LogPath "audit-$(Get-Date -Format 'yyyy-MM').log"
        $auditJson = $auditEntry | ConvertTo-Json -Compress
        Add-Content -Path $auditLogPath -Value $auditJson -Encoding UTF8
        
        Write-ReSetLog "Audit log entry created for $OperationType operation" "INFO"
        
    } catch {
        Write-ReSetLog "Error writing audit log: $($_.Exception.Message)" "ERROR"
    }
}

function Test-MaintenanceWindow {
    <#
    .SYNOPSIS
        Tests if current time is within the allowed maintenance window
    .DESCRIPTION
        Checks Group Policy defined maintenance windows for operation execution
    #>
    [CmdletBinding()]
    param()
    
    try {
        $policyConfig = Get-GroupPolicyConfiguration
        
        if (-not $policyConfig.EffectiveSettings.MaintenanceWindowActive) {
            return @{
                InWindow = $true
                Message = "No maintenance window restrictions"
            }
        }
        
        $maintenanceWindow = $policyConfig.ComputerPolicy.MaintenanceWindow
        if ([string]::IsNullOrEmpty($maintenanceWindow)) {
            return @{
                InWindow = $true
                Message = "No maintenance window defined"
            }
        }
        
        # Parse maintenance window (format: "HH:mm-HH:mm" or "HH-HH")
        $windowParts = $maintenanceWindow -split "-"
        if ($windowParts.Count -ne 2) {
            Write-ReSetLog "Invalid maintenance window format: $maintenanceWindow" "WARN"
            return @{
                InWindow = $true
                Message = "Invalid maintenance window format, allowing operation"
            }
        }
        
        $currentTime = Get-Date
        $startTime = [DateTime]::ParseExact($windowParts[0], "HH", $null)
        $endTime = [DateTime]::ParseExact($windowParts[1], "HH", $null)
        
        # Handle overnight windows (e.g., 22-06)
        if ($endTime -lt $startTime) {
            $inWindow = ($currentTime.Hour -ge $startTime.Hour) -or ($currentTime.Hour -le $endTime.Hour)
        } else {
            $inWindow = ($currentTime.Hour -ge $startTime.Hour) -and ($currentTime.Hour -le $endTime.Hour)
        }
        
        return @{
            InWindow = $inWindow
            Message = if ($inWindow) { 
                "Current time is within maintenance window ($maintenanceWindow)" 
            } else { 
                "Current time is outside maintenance window ($maintenanceWindow)" 
            }
            Window = $maintenanceWindow
            CurrentHour = $currentTime.Hour
        }
        
    } catch {
        Write-ReSetLog "Error checking maintenance window: $($_.Exception.Message)" "ERROR"
        return @{
            InWindow = $true
            Message = "Error checking maintenance window, allowing operation"
        }
    }
}

function Assert-GroupPolicyCompliance {
    <#
    .SYNOPSIS
        Asserts that an operation is compliant with Group Policy before execution
    .DESCRIPTION
        Comprehensive compliance check that throws if operation should not proceed
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationType,
        
        [Parameter(Mandatory = $true)]
        [string]$OperationName,
        
        [Parameter()]
        [switch]$IgnoreMaintenanceWindow
    )
    
    try {
        # Check basic compliance
        $compliance = Test-GroupPolicyCompliance -OperationType $OperationType
        
        if (-not $compliance.Allowed) {
            $message = "Operation blocked by Group Policy: $($compliance.Restrictions -join '; ')"
            Write-GroupPolicyAuditLog -OperationType $OperationType -OperationName $OperationName -Status "Blocked" -Details $message -Compliance $compliance
            throw $message
        }
        
        # Check maintenance window unless ignored
        if (-not $IgnoreMaintenanceWindow) {
            $windowCheck = Test-MaintenanceWindow
            if (-not $windowCheck.InWindow) {
                $message = "Operation blocked: $($windowCheck.Message)"
                Write-GroupPolicyAuditLog -OperationType $OperationType -OperationName $OperationName -Status "Blocked" -Details $message
                throw $message
            }
        }
        
        Write-ReSetLog "Group Policy compliance check passed for '$OperationName'" "SUCCESS"
        Write-GroupPolicyAuditLog -OperationType $OperationType -OperationName $OperationName -Status "Started" -Compliance $compliance
        
    } catch {
        Write-ReSetLog "Group Policy compliance check failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# ===================================================================
# ENHANCED SILENT MODE FUNCTIONS
# ===================================================================

function Invoke-SilentResetOperation {
    <#
    .SYNOPSIS
        Executes reset operations in silent mode for GPO deployment
    .DESCRIPTION
        Provides comprehensive silent execution with logging and error handling
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        
        [Parameter()]
        [hashtable]$Parameters = @{},
        
        [Parameter()]
        [string]$ConfigurationFile,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [int]$TimeoutMinutes = 30
    )
    
    try {
        # Load configuration if provided
        if ($ConfigurationFile -and (Test-Path $ConfigurationFile)) {
            $config = Get-Content $ConfigurationFile | ConvertFrom-Json
            foreach ($key in $config.PSObject.Properties.Name) {
                if (-not $Parameters.ContainsKey($key)) {
                    $Parameters[$key] = $config.$key
                }
            }
        }
        
        # Check Group Policy compliance
        Assert-GroupPolicyCompliance -OperationType "Reset" -OperationName $ScriptName
        
        # Prepare script execution parameters
        $scriptPath = Join-Path $PSScriptRoot "$ScriptName.ps1"
        if (-not (Test-Path $scriptPath)) {
            throw "Script not found: $scriptPath"
        }
        
        # Build parameter list
        $paramList = @("-Silent")
        if ($Force) { $paramList += "-Force" }
        
        foreach ($param in $Parameters.GetEnumerator()) {
            if ($param.Value -is [bool] -and $param.Value) {
                $paramList += "-$($param.Key)"
            } elseif ($param.Value -isnot [bool]) {
                $paramList += "-$($param.Key)", $param.Value
            }
        }
        
        Write-ReSetLog "Executing silent operation: $ScriptName with parameters: $($paramList -join ' ')" "INFO"
        
        # Execute with timeout
        $job = Start-Job -ScriptBlock {
            param($ScriptPath, $ParamList)
            & $ScriptPath @ParamList
        } -ArgumentList $scriptPath, $paramList
        
        $completed = Wait-Job -Job $job -Timeout ($TimeoutMinutes * 60)
        
        if ($completed) {
            $result = Receive-Job -Job $job
            $exitCode = $job.State -eq "Completed" ? 0 : 1
            
            Write-ReSetLog "Silent operation completed: $ScriptName (Exit Code: $exitCode)" "SUCCESS"
            Write-GroupPolicyAuditLog -OperationType "Reset" -OperationName $ScriptName -Status "Completed" -Details "Exit Code: $exitCode"
            
            return @{
                Success = $job.State -eq "Completed"
                ExitCode = $exitCode
                Output = $result
                ExecutionTime = (Get-Date) - $job.PSBeginTime
            }
        } else {
            Stop-Job -Job $job
            Write-ReSetLog "Silent operation timed out: $ScriptName (Timeout: $TimeoutMinutes minutes)" "ERROR"
            Write-GroupPolicyAuditLog -OperationType "Reset" -OperationName $ScriptName -Status "Failed" -Details "Operation timed out"
            
            return @{
                Success = $false
                ExitCode = -1
                Output = "Operation timed out"
                ExecutionTime = [TimeSpan]::FromMinutes($TimeoutMinutes)
            }
        }
        
    } catch {
        Write-ReSetLog "Error in silent operation: $($_.Exception.Message)" "ERROR"
        Write-GroupPolicyAuditLog -OperationType "Reset" -OperationName $ScriptName -Status "Failed" -Details $_.Exception.Message
        
        return @{
            Success = $false
            ExitCode = -1
            Output = $_.Exception.Message
            ExecutionTime = [TimeSpan]::Zero
        }
    } finally {
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    }
}

# ===================================================================
# EXPORT MODULE MEMBERS (UPDATED WITH GPO FUNCTIONS)
# ===================================================================

Export-ModuleMember -Function @(
    'Write-ReSetLog',
    'Start-ReSetOperation',
    'Complete-ReSetOperation',
    'New-ReSetBackup',
    'Restore-ReSetBackup',
    'Get-ReSetBackupList',
    'Remove-ReSetBackup',
    'Test-ReSetBackup',
    'Export-ReSetBackup',
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
    'Confirm-ReSetOperation',
    'Get-SystemHealth',
    'Invoke-AdvancedCleanup',
    'Test-ActiveDirectoryConnectivity',
    'Reset-ActiveDirectoryCache',
    'New-CompressedBackup',
    'Invoke-SystemReport',
    'Test-GroupPolicyCompliance',
    'Get-GroupPolicyConfiguration',
    'Invoke-GroupPolicyRefresh',
    'Update-ToolkitConfiguration',
    'Write-GroupPolicyAuditLog',
    'Test-MaintenanceWindow',
    'Assert-GroupPolicyCompliance',
    'Invoke-SilentResetOperation'
)
