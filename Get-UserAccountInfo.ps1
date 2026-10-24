<#
.SYNOPSIS
    Get-UserAccountInfo.ps1 — Read-only account/session info for the current user.
.DESCRIPTION
    READ-ONLY. Answers the questions that come up on account tickets:
    who is logged on, are they a local admin, which groups do they belong to,
    when does their password expire, and (on domain-joined machines) the basic
    domain account view. Uses built-in tools only (whoami, net user).
.EXAMPLE
    .\Get-UserAccountInfo.ps1
    .\Get-UserAccountInfo.ps1 -UserName "tariq.zaman"
#>
param(
    [string]$UserName = $env:USERNAME
)

Write-Host "================ SESSION ================"
whoami
whoami /groups | Select-String -Pattern "S-1-5-32-544|Mandatory Label" | ForEach-Object { $_.Line.Trim() }
# S-1-5-32-544 = BUILTIN\Administrators. Presence (not 'deny only') means this session has admin membership.

Write-Host "`n================ ACCOUNT: $UserName ================"
net user $UserName 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "No LOCAL account named '$UserName' (it may be a domain or Microsoft account)."
}

Write-Host "`n================ LAST LOGONS (this machine) ================"
Get-CimInstance Win32_NetworkLoginProfile -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "*$UserName*" } |
    Select-Object Name, LastLogon, NumberOfLogons |
    Format-Table -AutoSize

Write-Host "Tip: for a locked/expired DOMAIN account, also check Active Directory Users"
Write-Host "and Computers — a local report cannot see domain-side lockout state."
