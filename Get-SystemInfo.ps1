<#
.SYNOPSIS
    Get-SystemInfo.ps1 — Collects basic system information into a text report.
.DESCRIPTION
    READ-ONLY. Gathers the details a helpdesk engineer asks for on almost every
    ticket (computer name, Windows version, CPU, RAM, disks, IP addresses,
    logged-on user, uptime) and writes them to a timestamped .txt file.
    Nothing on the machine is changed.
.EXAMPLE
    .\Get-SystemInfo.ps1
    .\Get-SystemInfo.ps1 -OutputFolder "C:\Reports"
#>
param(
    [string]$OutputFolder = $PSScriptRoot
)

$os      = Get-CimInstance Win32_OperatingSystem
$cs      = Get-CimInstance Win32_ComputerSystem
$cpu     = Get-CimInstance Win32_Processor | Select-Object -First 1
$disks   = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$uptime  = (Get-Date) - $os.LastBootUpTime

$report = @"
================ SYSTEM INFORMATION REPORT ================
Generated        : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Computer Name    : $($env:COMPUTERNAME)
Logged-on User   : $env:USERNAME  ($env:USERDOMAIN)
Windows          : $($os.Caption)  (Build $($os.BuildNumber))
Install Date     : $($os.InstallDate)
Manufacturer     : $($cs.Manufacturer)
Model            : $($cs.Model)
CPU              : $($cpu.Name)
RAM (GB)         : $([math]::Round($cs.TotalPhysicalMemory / 1GB, 1))
Last Boot        : $($os.LastBootUpTime)
Uptime           : $([int]$uptime.TotalDays) days, $($uptime.Hours) hours

---------------- FIXED DISKS ----------------
$($disks | ForEach-Object { "{0}  Size: {1} GB  Free: {2} GB ({3}%)" -f $_.DeviceID, [math]::Round($_.Size/1GB,1), [math]::Round($_.FreeSpace/1GB,1), [math]::Round(($_.FreeSpace/$_.Size)*100,0) } | Out-String)
---------------- NETWORK ADAPTERS (Up) ----------------
$(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike '169.254.*' } |
    ForEach-Object { "{0} : {1}" -f $_.InterfaceAlias, $_.IPAddress } | Out-String)
===========================================================
"@

$report | Write-Host

$fileName = "SystemInfo_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$outPath  = Join-Path $OutputFolder $fileName
$report | Out-File -FilePath $outPath -Encoding UTF8
Write-Host "Report saved to: $outPath" -ForegroundColor Green
