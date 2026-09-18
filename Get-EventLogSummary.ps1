#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(1, 30)]
    [int]$Days = 1,
    [Parameter()]
    [ValidateRange(1, 500)]
    [int]$MaximumEvents = 100,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Join-Path $env:USERPROFILE 'Desktop\Momentum-ClientReports')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') { throw 'Dieses Skript kann nur auf Windows-Clients ausgeführt werden.' }
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$start = (Get-Date).AddDays(-$Days)
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logs = 'System', 'Application', 'Security'

$events = foreach ($log in $logs) {
    try {
        Get-WinEvent -FilterHashtable @{ LogName = $log; Level = 1, 2, 3; StartTime = $start } -MaxEvents $MaximumEvents -ErrorAction Stop | Select-Object TimeCreated, LogName, Id, ProviderName, LevelDisplayName, Message
    } catch {
        Write-Verbose "Log $log konnte nicht gelesen werden: $($_.Exception.Message)"
    }
}

$events = @($events | Sort-Object TimeCreated -Descending)
$summary = [pscustomobject]@{
    GeneratedAt = (Get-Date).ToString('o')
    Since = $start
    EventCount = $events.Count
    ByLog = @($events | Group-Object LogName | Select-Object Name, Count)
    ByLevel = @($events | Group-Object LevelDisplayName | Select-Object Name, Count)
    Events = $events
}
$jsonPath = Join-Path $OutputPath "EventLogSummary-$timestamp.json"
$csvPath = Join-Path $OutputPath "EventLogSummary-$timestamp.csv"
$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8
$events | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
[pscustomobject]@{ Json = $jsonPath; Csv = $csvPath; EventCount = $events.Count; GeneratedAt = Get-Date }
