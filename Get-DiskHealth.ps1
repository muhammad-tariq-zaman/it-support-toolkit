<#
.SYNOPSIS
    Get-DiskHealth.ps1 — Read-only disk health and free-space report.
.DESCRIPTION
    READ-ONLY. Reports each physical disk's health and operational status
    (from Windows storage APIs, which surface SMART status where available),
    plus per-volume size/free space with a warning flag under 10% free.
    Useful before imaging a failing drive — and as evidence on the ticket.
.EXAMPLE
    .\Get-DiskHealth.ps1
#>

Write-Host "================ PHYSICAL DISKS ================"
Get-PhysicalDisk -ErrorAction SilentlyContinue | ForEach-Object {
    $colour = if ($_.HealthStatus -eq 'Healthy') { 'Green' } else { 'Red' }
    Write-Host ("{0}  |  {1}  |  {2} GB  |  Media: {3}  |  Bus: {4}" -f `
        $_.FriendlyName, $_.HealthStatus, [math]::Round($_.Size/1GB,0), $_.MediaType, $_.BusType) -ForegroundColor $colour
    Write-Host ("   Operational status: {0}" -f ($_.OperationalStatus -join ', '))
}

Write-Host "`n================ VOLUMES ================"
Get-Volume -ErrorAction SilentlyContinue |
    Where-Object { $_.DriveLetter } | ForEach-Object {
        $freePct = if ($_.Size -gt 0) { [math]::Round(($_.SizeRemaining / $_.Size) * 100, 0) } else { 0 }
        $line = "{0}:  {1} GB total, {2} GB free ({3}% free)" -f $_.DriveLetter, `
            [math]::Round($_.Size/1GB,1), [math]::Round($_.SizeRemaining/1GB,1), $freePct
        if ($freePct -lt 10) { Write-Host "$line   <-- LOW SPACE WARNING" -ForegroundColor Red }
        else                 { Write-Host $line }
    }

Write-Host "`nNote: a 'Healthy' status is a good sign, not a guarantee. If a disk clicks,"
Write-Host "disappears intermittently, or SMART tools report reallocated sectors, back up FIRST."
