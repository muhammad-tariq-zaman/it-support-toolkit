<#
.SYNOPSIS
    Clear-TempFiles.ps1 — Safely clears old temp files, WITH confirmation.
.DESCRIPTION
    For the classic "C: is full" ticket. Safety design:
      * Measures first and SHOWS you the space involved before deleting anything
      * Only files OLDER THAN 7 DAYS in temp folders are candidates
      * Requires you to type Y — there is no silent mode on purpose
      * Skips files that are in use (locked) instead of forcing anything
      * NEVER touches Documents, Downloads, Desktop, or the Recycle Bin
.EXAMPLE
    .\Clear-TempFiles.ps1
#>
param(
    [int]$OlderThanDays = 7
)

$targets = @($env:TEMP, "$env:SystemRoot\Temp") | Select-Object -Unique
$cutoff  = (Get-Date).AddDays(-$OlderThanDays)

$candidates = foreach ($t in $targets) {
    Get-ChildItem -Path $t -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }
}
$totalMB = [math]::Round((($candidates | Measure-Object Length -Sum).Sum) / 1MB, 1)

Write-Host "Temp cleanup preview"
Write-Host "  Folders : $($targets -join ', ')"
Write-Host "  Files older than $OlderThanDays days: $($candidates.Count)  (~$totalMB MB)"

if ($candidates.Count -eq 0) { Write-Host "Nothing to clean. Done."; return }

$answer = Read-Host "Delete these temp files now? (Y/N)"
if ($answer -notin 'Y','y') { Write-Host "Cancelled — nothing was deleted."; return }

$deleted = 0; $skipped = 0
foreach ($f in $candidates) {
    try   { Remove-Item $f.FullName -Force -ErrorAction Stop; $deleted++ }
    catch { $skipped++ }   # locked/in-use files are skipped, never forced
}
Write-Host "Deleted: $deleted files. Skipped (in use): $skipped files." -ForegroundColor Green
Write-Host "Tip: if C: is still full, check the user's profile folders and Windows Update cleanup next — manually, with the user present."
