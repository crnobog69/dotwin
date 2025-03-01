==========================================================================
Save the this as "Windows_Cleanup.cmd" (Batch File)

powershell.exe -ExecutionPolicy Bypass -File "%~dp0\Windows_Cleanup.ps1"
pause

==========================================================================
Save this as "Windows_Cleanup.PS1" (Power shell Script)

# Written by Fabian Castagna
# Used as a complete windows cleanup tool
# 15-7-2016
function Delete-ComputerRestorePoints {
    [CmdletBinding(SupportsShouldProcess = $True)]param(  
        [Parameter(
            Position = 0, 
            Mandatory = $true, 
            ValueFromPipeline = $true
        )]
        $restorePoints
    )
    begin {
        $fullName = "SystemRestore.DeleteRestorePoint"
        #check if the type is already loaded
        $isLoaded = ([AppDomain]::CurrentDomain.GetAssemblies() | foreach { $_.GetTypes() } | where { $_.FullName -eq $fullName }) -ne $null
        if (!$isLoaded) {
            $SRClient = Add-Type   -memberDefinition  @"
		    	[DllImport ("Srclient.dll")]
		        public static extern int SRRemoveRestorePoint (int index);
"@  -Name DeleteRestorePoint -NameSpace SystemRestore -PassThru
        }
    }
    process {
        foreach ($restorePoint in $restorePoints) {
            if ($PSCmdlet.ShouldProcess("$($restorePoint.Description)", "Deleting Restorepoint")) {
                [SystemRestore.DeleteRestorePoint]::SRRemoveRestorePoint($restorePoint.SequenceNumber)
            }
        }
    }
}

Write-Host "Deleting System Restore Points"
Get-ComputerRestorePoint | Delete-ComputerRestorePoints # -WhatIf

Write-host "Checking to make sure you have Local Admin rights" -foreground yellow
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    If (!($psISE)) { "Press any key to continue…"; [void][System.Console]::ReadKey($true) }
    Exit 1
}

Write-Host "Capture current free disk space on Drive C" -foreground yellow
$FreespaceBefore = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace / 1GB

Write-host "Deleting Rouge folders" -foreground yellow
if (test-path C:\Config.Msi) { remove-item -Path C:\Config.Msi -force -recurse }
if (test-path c:\Intel) { remove-item -Path c:\Intel -force -recurse }
if (test-path c:\PerfLogs) { remove-item -Path c:\PerfLogs -force -recurse }
# if (test-path c:\swsetup) {remove-item -Path c:\swsetup -force -recurse} # HP Software and Driver Repositry
if (test-path $env:windir\memory.dmp) { remove-item $env:windir\memory.dmp -force }

Write-host "Deleting Windows Error Reporting files" -foreground yellow
if (test-path C:\ProgramData\Microsoft\Windows\WER) { Get-ChildItem -Path C:\ProgramData\Microsoft\Windows\WER -Recurse | Remove-Item -force -recurse }

Write-host "Removing System and User Temp Files" -foreground yellow
Remove-Item -Path "$env:windir\Temp\*" -Force -Recurse
Remove-Item -Path "$env:windir\minidump\*" -Force -Recurse
Remove-Item -Path "$env:windir\Prefetch\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Temp\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\WER\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\IECompatCache\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\IECompatUaCache\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\IEDownloadHistory\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\INetCookies\*" -Force -Recurse
Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Terminal Server Client\Cache\*" -Force -Recurse

Write-host "Removing Windows Updates Downloads" -foreground yellow
Stop-Service wuauserv -Force -Verbose
Stop-Service TrustedInstaller -Force -Verbose
Remove-Item -Path "$env:windir\SoftwareDistribution\*" -Force -Recurse
Remove-Item $env:windir\Logs\CBS\* -force -recurse
Start-Service wuauserv -Verbose
Start-Service TrustedInstaller -Verbose

Write-host "Checkif Windows Cleanup exists" -foreground yellow
#Mainly for 2008 servers
if (!(Test-Path c:\windows\System32\cleanmgr.exe)) {
    Write-host "Windows Cleanup NOT installed now installing" -foreground yellow
    copy-item $env:windir\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.1.7600.16385_none_c9392808773cd7da\cleanmgr.exe $env:windir\System32
    copy-item $env:windir\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.1.7600.16385_en-us_b9cb6194b257cc63\cleanmgr.exe.mui $env:windir\System32\en-US
}


Write-host "Running Windows System Cleanup" -foreground yellow
#Set StateFlags setting for each item in Windows disk cleanup utility
$StateFlags = 'StateFlags0013'
$StateRun = $StateFlags.Substring($StateFlags.get_Length() - 2)
$StateRun = '/sagerun:' + $StateRun 
if (-not (get-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders' -name $StateFlags)) {
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Offline Pages Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Memory Dump Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Archive Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Queue Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Archive Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Queue Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Temp Files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files' -name $StateFlags -type DWORD -Value 2
    set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files' -name $StateFlags -type DWORD -Value 2
}

Write-host "Starting CleanMgr.exe.." -foreground yellow
Start-Process -FilePath CleanMgr.exe -ArgumentList $StateRun  -WindowStyle Hidden -Wait

Write-host "Clearing All Event Logs" -foreground yellow
wevtutil el | Foreach-Object { Write-Host "Clearing $_"; wevtutil cl "$_" }

Write-host "Disk Usage before and after cleanup" -foreground yellow
$FreespaceAfter = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace / 1GB
"Free Space Before: {0}" -f $FreespaceBefore
"Free Space After: {0}" -f $FreespaceAfter