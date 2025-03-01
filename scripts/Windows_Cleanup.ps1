
# Windows Cleanup Tool
# Enhanced version with error handling and logging

# Setup logging
$LogPath = Join-Path $env:TEMP "WindowsCleanup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Host $logMessage
    Add-Content -Path $LogPath -Value $logMessage
}

# Check for admin rights
Write-Log "Checking administrator rights..."
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Log "ERROR: Script requires administrator privileges"
    throw "Please run this script as an Administrator"
}

# Capture initial free space
$FreespaceBefore = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | Select-Object -ExpandProperty FreeSpace) / 1GB
Write-Log "Initial free space: $($FreespaceBefore.ToString('N2')) GB"

# Safe file deletion function
function Remove-ItemSafely {
    param (
        [string]$Path,
        [switch]$Recurse
    )
    if (Test-Path $Path) {
        try {
            Remove-Item -Path $Path -Force -Recurse:$Recurse -ErrorAction Stop
            Write-Log "Successfully removed: $Path"
        }
        catch {
            Write-Log "WARNING: Failed to remove $Path - $($_.Exception.Message)"
        }
    }
}

# Cleanup System Restore Points
Write-Log "Cleaning up System Restore Points..."
try {
    $restorePoints = Get-ComputerRestorePoint
    if ($restorePoints) {
        $restorePoints | ForEach-Object {
            Write-Log "Removing restore point: $($_.Description)"
            $_ | Delete-ComputerRestorePoints
        }
    }
}
catch {
    Write-Log "WARNING: Error cleaning restore points - $($_.Exception.Message)"
}

# Clean common system folders
$foldersToClean = @(
    "$env:windir\Temp",
    "$env:windir\Prefetch",
    "$env:windir\SoftwareDistribution\Download",
    "$env:windir\Logs\CBS",
    "C:\Users\*\AppData\Local\Temp",
    "C:\Users\*\AppData\Local\Microsoft\Windows\WER",
    "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache"
)

foreach ($folder in $foldersToClean) {
    Write-Log "Cleaning $folder"
    Remove-ItemSafely -Path $folder -Recurse
}

# Windows Update Service cleanup
Write-Log "Cleaning Windows Update cache..."
try {
    Stop-Service -Name wuauserv -Force
    Remove-ItemSafely -Path "$env:windir\SoftwareDistribution" -Recurse
    Start-Service -Name wuauserv
}
catch {
    Write-Log "WARNING: Error cleaning Windows Update - $($_.Exception.Message)"
}

# Run System Disk Cleanup
Write-Log "Initializing System Disk Cleanup..."
if (Test-Path "$env:windir\System32\cleanmgr.exe") {
    try {
        $StateFlags = 'StateFlags0013'
        $paths = @(
            'Active Setup Temp Folders', 'Internet Cache Files', 'Memory Dump Files',
            'Recycle Bin', 'Temporary Files', 'Windows Error Reporting Files'
        )
        
        foreach ($path in $paths) {
            $regPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\$path"
            if (Test-Path $regPath) {
                Set-ItemProperty -Path $regPath -Name $StateFlags -Type DWORD -Value 2
            }
        }

        Write-Log "Running Disk Cleanup..."
        Start-Process -FilePath cleanmgr.exe -ArgumentList "/sagerun:13" -Wait
    }
    catch {
        Write-Log "WARNING: Error running Disk Cleanup - $($_.Exception.Message)"
    }
}
else {
    Write-Log "WARNING: CleanMgr.exe not found"
}

# Calculate space saved
$FreespaceAfter = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | Select-Object -ExpandProperty FreeSpace) / 1GB
$SpaceSaved = $FreespaceAfter - $FreespaceBefore

Write-Log "Cleanup Complete!"
Write-Log "Space saved: $($SpaceSaved.ToString('N2')) GB"
Write-Log "Final free space: $($FreespaceAfter.ToString('N2')) GB"
Write-Log "Log file saved to: $LogPath"
