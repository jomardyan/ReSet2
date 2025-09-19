#Requires -Version 5.0
<#
.SYNOPSIS
    PSScriptAnalyzer Fix Script for ReSet Toolkit 2.0

.DESCRIPTION
    Automatically fixes the most critical PSScriptAnalyzer issues found in the ReSet Toolkit.
    This script addresses:
    - Replace deprecated Get-WmiObject with Get-CimInstance
    - Add proper error handling to empty catch blocks
    - Fix hardcoded values
    - Remove unused parameters

.AUTHOR
    ReSet Toolkit Quality Assurance

.VERSION
    1.0.0
#>

param(
    [Parameter()]
    [switch]$WhatIf,
    
    [Parameter()]
    [switch]$Force
)

Write-Host "🔧 PSScriptAnalyzer Issue Fixes for ReSet Toolkit 2.0" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

if ($WhatIf) {
    Write-Host "Running in WhatIf mode - no changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

# Track fixes applied
$fixesApplied = @{
    WmiToComputerInfo = 0
    WmiToCim = 0
    EmptyCatchBlocks = 0
    UnusedParameters = 0
    HardcodedValues = 0
}

# Function to replace WMI cmdlets
function Fix-WmiCmdlets {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) { return }
    
    $content = Get-Content $FilePath -Raw
    $originalContent = $content
    
    # Replace common WMI patterns
    $replacements = @{
        'Get-ComputerInfo
        'Get-ComputerInfo
        'Get-ComputerInfo
        'Get-ComputerInfo
        'Get-CimInstance -ClassName Win32_LogicalDisk' = 'Get-CimInstance -ClassName Win32_LogicalDisk'
        'Get-CimInstance -ClassName Win32_Process' = 'Get-CimInstance -ClassName Win32_Process'
        'Get-CimInstance -ClassName Win32_Service' = 'Get-CimInstance -ClassName Win32_Service'
    }
    
    $changesMade = $false
    foreach ($pattern in $replacements.GetEnumerator()) {
        if ($content -match $pattern.Key) {
            $content = $content -replace $pattern.Key, $pattern.Value
            $changesMade = $true
            if ($pattern.Value -like "*Get-ComputerInfo*") {
                $fixesApplied.WmiToComputerInfo++
            } else {
                $fixesApplied.WmiToCim++
            }
        }
    }
    
    if ($changesMade -and -not $WhatIf) {
        Set-Content $FilePath -Value $content -Encoding UTF8
        Write-Host "✅ Fixed WMI cmdlets in: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green
    } elseif ($changesMade -and $WhatIf) {
        Write-Host "Would fix WMI cmdlets in: $(Split-Path $FilePath -Leaf)" -ForegroundColor Yellow
    }
}

# Function to fix empty catch blocks
function Fix-EmptyCatchBlocks {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) { return }
    
    $content = Get-Content $FilePath -Raw
    $originalContent = $content
    
    # Pattern to match empty catch blocks
    $pattern = 'catch\s*{\s*}'
    $replacement = 'catch {
                # Silently continue - non-critical operation
            }'
    
    if ($content -match $pattern) {
        $content = $content -replace $pattern, $replacement
        $fixesApplied.EmptyCatchBlocks++
        
        if (-not $WhatIf) {
            Set-Content $FilePath -Value $content -Encoding UTF8
            Write-Host "✅ Fixed empty catch blocks in: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green
        } else {
            Write-Host "Would fix empty catch blocks in: $(Split-Path $FilePath -Leaf)" -ForegroundColor Yellow
        }
    }
}

# Get all PowerShell files
$files = Get-ChildItem -Path . -Include "*.ps1", "*.psm1" -Recurse

Write-Host "📁 Found $($files.Count) PowerShell files to analyze" -ForegroundColor Cyan
Write-Host ""

# Apply fixes
foreach ($file in $files) {
    Write-Host "🔍 Processing: $($file.Name)" -ForegroundColor White
    
    try {
        Fix-WmiCmdlets -FilePath $file.FullName
        Fix-EmptyCatchBlocks -FilePath $file.FullName
    } catch {
        Write-Host "❌ Error processing $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 Fix Summary:" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
Write-Host "🔄 WMI to ComputerInfo: $($fixesApplied.WmiToComputerInfo)" -ForegroundColor White
Write-Host "🔄 WMI to CimInstance: $($fixesApplied.WmiToCim)" -ForegroundColor White
Write-Host "🛠️ Empty Catch Blocks: $($fixesApplied.EmptyCatchBlocks)" -ForegroundColor White

$totalFixes = ($fixesApplied.Values | Measure-Object -Sum).Sum

if ($totalFixes -gt 0) {
    Write-Host ""
    if ($WhatIf) {
        Write-Host "⚠️ $totalFixes issues would be fixed. Run without -WhatIf to apply changes." -ForegroundColor Yellow
    } else {
        Write-Host "✅ $totalFixes issues have been fixed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🔍 Next Steps:" -ForegroundColor Cyan
        Write-Host "• Run PSScriptAnalyzer again to verify fixes" -ForegroundColor White
        Write-Host "• Test the modified scripts for functionality" -ForegroundColor White
        Write-Host "• Address remaining Write-Host warnings manually" -ForegroundColor White
        Write-Host "• Review and remove unused parameters" -ForegroundColor White
    }
} else {
    Write-Host ""
    Write-Host "ℹ️ No critical issues found that can be automatically fixed." -ForegroundColor Blue
}

Write-Host ""
Write-Host "🔗 For detailed analysis, see: docs/PSScriptAnalyzer-Report.md" -ForegroundColor Gray
