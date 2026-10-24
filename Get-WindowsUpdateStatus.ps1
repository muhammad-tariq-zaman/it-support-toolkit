<#
.SYNOPSIS
    Get-WindowsUpdateStatus.ps1 — Read-only Windows Update health check.
.DESCRIPTION
    READ-ONLY. When a machine "won't update", this tells you in 10 seconds
    whether the problem is a stopped service, a stuck pending reboot, or
    updates that genuinely never ran — then prints the OFFICIAL guided steps
    instead of the registry-breaking "fixes" that float around forums.
.EXAMPLE
    .\Get-WindowsUpdateStatus.ps1
#>

Write-Host "================ UPDATE SERVICES ================"
foreach ($name in 'wuauserv','BITS','CryptSvc','UsoSvc') {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($svc) { Write-Host ("{0,-10} Status: {1,-8} StartType: {2}" -f $name, $svc.Status, $svc.StartType) }
}

Write-Host "`n================ LAST UPDATE ACTIVITY ================"
try {
    $session  = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $count    = $searcher.GetTotalHistoryCount()
    if ($count -gt 0) {
        $searcher.QueryHistory(0, [Math]::Min(5, $count)) | ForEach-Object {
            Write-Host ("{0}  {1}  ->  {2}" -f $_.Date.ToString('yyyy-MM-dd'), $_.Title, $_.ResultCode)
            # ResultCode: 2 = Succeeded, 3 = Succeeded with errors, 4 = Failed
        }
    } else { Write-Host "No update history recorded." }
} catch { Write-Host "Could not read update history: $($_.Exception.Message)" }

Write-Host "`n================ PENDING REBOOT ================"
$pending = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') -or
           (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending')
Write-Host ("Pending reboot: {0}" -f $pending)

Write-Host "`n================ GUIDED NEXT STEPS (official, safe order) ================"
Write-Host "1. If a reboot is pending, reboot first — many 'failed' updates clear here."
Write-Host "2. Settings > Windows Update > Check for updates, and let it finish fully."
Write-Host "3. Settings > Troubleshoot > Other troubleshooters > Windows Update."
Write-Host "4. Check free disk space (updates need breathing room) — see Get-DiskHealth.ps1."
Write-Host "5. Still stuck? Note the error code shown in Settings and search it on"
Write-Host "   Microsoft Learn — fix by the code, not by random registry edits."
