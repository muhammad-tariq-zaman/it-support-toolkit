<#
.SYNOPSIS
    Restart-PrintSpooler.ps1 — Fixes "printer is stuck / nothing prints".
.DESCRIPTION
    The standard helpdesk fix for a jammed print queue:
      1. Stops the Print Spooler service
      2. Deletes the stuck spool files (ONLY the spool folder — never user files)
      3. Restarts the service
    ASKS FOR CONFIRMATION before doing anything, and requires an elevated
    (Run as Administrator) PowerShell window.
.EXAMPLE
    .\Restart-PrintSpooler.ps1
#>

# --- Admin check ------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Please re-run this script in an elevated PowerShell (Run as Administrator)." -ForegroundColor Yellow
    return
}

# --- Confirmation ------------------------------------------------------------
Write-Host "This will stop the Print Spooler, clear ALL waiting print jobs on this PC, and restart the service."
$answer = Read-Host "Continue? (Y/N)"
if ($answer -notin 'Y','y') { Write-Host "Cancelled — nothing was changed."; return }

# --- Do the work --------------------------------------------------------------
Write-Host "Stopping Print Spooler..."
Stop-Service -Name Spooler -Force -ErrorAction Stop

$spoolPath = "$env:SystemRoot\System32\spool\PRINTERS"
Write-Host "Clearing stuck jobs in $spoolPath ..."
Get-ChildItem -Path $spoolPath -File -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "Starting Print Spooler..."
Start-Service -Name Spooler

$svc = Get-Service -Name Spooler
Write-Host "Done. Spooler status: $($svc.Status). Ask the user to print a test page." -ForegroundColor Green
