<#
.SYNOPSIS
    Get-SoftwareInventory.ps1 — Exports installed software to CSV.
.DESCRIPTION
    READ-ONLY (reads the standard uninstall registry keys; writes one CSV).
    I use this during asset-inventory updates so the register matches what is
    actually installed, instead of what was installed on day one.
.EXAMPLE
    .\Get-SoftwareInventory.ps1
    .\Get-SoftwareInventory.ps1 -OutputPath "C:\Inventory\pc-042.csv"
#>
param(
    [string]$OutputPath = (Join-Path $PSScriptRoot "SoftwareInventory_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd').csv")
)

$keys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

$apps = Get-ItemProperty $keys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Sort-Object DisplayName -Unique

$apps | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported $($apps.Count) programs to: $OutputPath" -ForegroundColor Green
