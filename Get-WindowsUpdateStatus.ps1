#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$IncludeAvailable,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Join-Path $env:USERPROFILE 'Desktop\Momentum-ClientReports')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') { throw 'Dieses Skript kann nur auf Windows-Clients ausgeführt werden.' }
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$services = @('wuauserv', 'bits', 'UsoSvc') | ForEach-Object {
    $service = Get-Service -Name $_ -ErrorAction SilentlyContinue
    [pscustomobject]@{ Name = $_; Status = if ($service) { $service.Status.ToString() } else { 'Nicht vorhanden' }; StartType = if ($service) { $service.StartType.ToString() } else { 'Unbekannt' } }
}
$hotfixes = @(Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 20 HotFixID, Description, InstalledOn, InstalledBy)
$events = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WindowsUpdateClient'; StartTime = (Get-Date).AddDays(-30) } -MaxEvents 50 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, LevelDisplayName, Message)
$available = @()
if ($IncludeAvailable) {
    try {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        $result = $searcher.Search("IsInstalled=0 and IsHidden=0")
        $available = @($result.Updates | ForEach-Object { [pscustomobject]@{ Title = $_.Title; KBArticleIDs = @($_.KBArticleIDs); IsDownloaded = $_.IsDownloaded; SizeMB = [math]::Round($_.MaxDownloadSize / 1MB, 2) } })
    } catch { Write-Warning "Verfügbare Updates konnten nicht abgefragt werden: $($_.Exception.Message)" }
}
$report = [pscustomobject]@{ GeneratedAt = (Get-Date).ToString('o'); Services = @($services); RecentHotFixes = $hotfixes; WindowsUpdateEvents = $events; AvailableUpdates = $available }
$jsonPath = Join-Path $OutputPath "WindowsUpdate-$timestamp.json"
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8
[pscustomobject]@{ Json = $jsonPath; InstalledHotFixes = $hotfixes.Count; AvailableUpdates = $available.Count; GeneratedAt = Get-Date }
