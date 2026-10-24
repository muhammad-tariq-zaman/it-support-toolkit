# IT Support Toolkit 🧰

A small collection of **safe** PowerShell and Batch scripts I use in day-to-day IT support work on Windows 10/11 machines — the same tasks that come up again and again on helpdesk tickets: collecting system info for a ticket, checking why the network "is down", un-sticking a printer queue, checking a disk before it fails, and exporting a software list for the asset inventory.

## Safety rules (applied to every script here)

- **Read-only by default.** Scripts that only gather information never change anything.
- **Anything that changes the system asks first.** You get a clear `Y/N` confirmation prompt — no silent changes, ever.
- **No destructive defaults.** Nothing here deletes user documents, formats anything, edits the registry, or disables security features.
- **Commented and plain.** Every script explains what it does at the top, so a colleague can review it before running it.
- **Admin rights:** scripts that need elevation check for it and tell you, instead of failing mysteriously.

## The scripts

| Script | What it does | Changes anything? |
|---|---|---|
| `Get-SystemInfo.ps1` | Collects computer name, Windows version/build, CPU, RAM, disk sizes, IP addresses, logged-on user, and uptime into a timestamped text report — perfect to attach to a ticket. | No — read-only |
| `Test-NetworkDiagnostics.ps1` | The classic "is it the PC, the LAN, or the internet?" sequence: adapter/IP config, default gateway ping, DNS server ping, internet ping (8.8.8.8), and a DNS lookup test. Optional `-FlushDns` switch clears the DNS cache. | Only with `-FlushDns` (you choose) |
| `Restart-PrintSpooler.ps1` | Clears stuck print jobs the safe way: stops the Print Spooler, clears the spool folder, restarts the service. Asks for confirmation first; needs admin. | Yes — after Y/N prompt; spool files only |
| `Get-DiskHealth.ps1` | Read-only disk health report: physical disk health/operational status, volume free space, and a low-space warning list. Uses SMART status where Windows exposes it. | No — read-only |
| `Get-UserAccountInfo.ps1` | Who is logged on, local account details, group membership, password expiry info, and (on domain machines) basic AD account status via `whoami` / `net user`. | No — read-only |
| `Get-SoftwareInventory.ps1` | Exports installed software (name, version, publisher, install date) from the standard uninstall registry keys to a CSV — used for asset-inventory updates. | No — reads registry, writes one CSV |
| `Clear-TempFiles.ps1` | Shows how much space temp folders are using, then — **only after you type Y** — deletes temp files older than 7 days. Skips files that are in use; never touches Documents/Downloads/Desktop. | Yes — after Y prompt; temp files only |
| `Get-WindowsUpdateStatus.ps1` | Read-only Windows Update health check: service states (wuauserv, BITS, CryptSvc), last update search/install dates, and pending-reboot flag. Prints the official guided next steps instead of "fixing" anything automatically. | No — read-only |

## How to run

```powershell
# If your execution policy blocks local scripts, allow them for this session only:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.\Get-SystemInfo.ps1
.\Test-NetworkDiagnostics.ps1
.\Get-SoftwareInventory.ps1 -OutputPath "$env:USERPROFILE\Desktop\software.csv"
```

Reports are written next to the script (or to the path you pass), with the computer name and date in the filename, so a folder of reports stays sortable.

## Why I made this

On a busy helpdesk, the difference between a 5-minute fix and a 45-minute one is usually *having the basics ready*. These scripts are my basics — written to be boring, predictable, and safe to run on someone else's machine while they watch.

Contributions and corrections welcome — especially from other support engineers. If a script misbehaves on your build of Windows, open an issue with the output of `Get-SystemInfo.ps1` attached (remove anything personal first).

## License

MIT — use them at work, adapt them to your environment, and please keep the safety prompts in.
