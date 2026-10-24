<#
.SYNOPSIS
    Test-NetworkDiagnostics.ps1 — Step-by-step "is the network really down?" check.
.DESCRIPTION
    READ-ONLY by default. Works outward from the machine, the same order a
    support engineer troubleshoots:
      1. IP configuration (do we even have an address?)
      2. Ping the default gateway      (is the local LAN reachable?)
      3. Ping the DNS server           (is DNS infrastructure reachable?)
      4. Ping 8.8.8.8                   (is the internet reachable by IP?)
      5. Resolve a public name         (does DNS actually work?)
    A failure tells you which layer to fix instead of guessing.
    Optional -FlushDns clears the local DNS resolver cache first.
.EXAMPLE
    .\Test-NetworkDiagnostics.ps1
    .\Test-NetworkDiagnostics.ps1 -FlushDns
#>
param([switch]$FlushDns)

function Test-Step {
    param([string]$Label, [bool]$Ok)
    $mark = if ($Ok) { "[ OK ]" } else { "[FAIL]" }
    Write-Host ("{0}  {1}" -f $mark, $Label) -ForegroundColor $(if ($Ok) { 'Green' } else { 'Red' })
    return $Ok
}

if ($FlushDns) {
    Write-Host "Clearing DNS resolver cache (ipconfig /flushdns)..."
    ipconfig /flushdns | Out-Null
}

Write-Host "`n--- Step 1: IP configuration ---"
$ip = Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | Select-Object -First 1
if (-not $ip) { Write-Host "No IPv4 address found on any adapter." -ForegroundColor Red; return }
Write-Host "Adapter : $($ip.InterfaceAlias)"
Write-Host "IPv4    : $($ip.IPv4Address.IPAddress)"
Write-Host "Gateway : $($ip.IPv4DefaultGateway.NextHop)"
Write-Host "DNS     : $($ip.DNSServer.ServerAddresses -join ', ')"

$gateway = $ip.IPv4DefaultGateway.NextHop
$dns     = ($ip.DNSServer.ServerAddresses | Select-Object -First 1)

Write-Host "`n--- Connectivity tests ---"
$gOk = Test-Step "Ping default gateway ($gateway)" (Test-Connection -ComputerName $gateway -Count 2 -Quiet -ErrorAction SilentlyContinue)
$dOk = Test-Step "Ping DNS server ($dns)"           (Test-Connection -ComputerName $dns -Count 2 -Quiet -ErrorAction SilentlyContinue)
$iOk = Test-Step "Ping internet by IP (8.8.8.8)"    (Test-Connection -ComputerName '8.8.8.8' -Count 2 -Quiet -ErrorAction SilentlyContinue)

$nameOk = $false
try { $null = Resolve-DnsName -Name 'www.microsoft.com' -ErrorAction Stop; $nameOk = $true } catch { }
$nOk = Test-Step "DNS name resolution (www.microsoft.com)" $nameOk

Write-Host "`n--- Reading the result ---"
if     ($gOk -and $iOk -and $nOk) { Write-Host "Network path looks healthy. The problem is probably the app/service, not the network." }
elseif (-not $gOk)                { Write-Host "Cannot reach the gateway: check cable/Wi-Fi, switch port, and that the adapter got a real (non-169.254) address." }
elseif ($gOk -and -not $iOk)      { Write-Host "LAN is fine but the internet is not: likely router/ISP side — escalate with these results attached." }
elseif ($iOk -and -not $nOk)      { Write-Host "Internet works by IP but names fail: DNS problem. Try the -FlushDns switch, then check the DNS server setting." }
