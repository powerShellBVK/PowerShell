#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Established', 'Listen', 'TimeWait', 'All')]
    [string]$State = 'Established',
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Join-Path $env:USERPROFILE 'Desktop\Momentum-ClientReports')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') { throw 'Dieses Skript kann nur auf Windows-Clients ausgeführt werden.' }
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$connections = switch ($State) {
    'All' { Get-NetTCPConnection -ErrorAction Stop }
    default { Get-NetTCPConnection -State $State -ErrorAction Stop }
}
$connections = @($connections)
$report = foreach ($connection in $connections) {
    $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
    [pscustomobject]@{
        State = $connection.State
        LocalAddress = $connection.LocalAddress
        LocalPort = $connection.LocalPort
        RemoteAddress = $connection.RemoteAddress
        RemotePort = $connection.RemotePort
        ProcessId = $connection.OwningProcess
        ProcessName = if ($process) { $process.ProcessName } else { 'Unbekannt' }
        ExecutablePath = if ($process) { try { $process.Path } catch { $null } } else { $null }
    }
}
$report = @($report | Sort-Object ProcessName, RemoteAddress, RemotePort)
$csvPath = Join-Path $OutputPath "ProcessNetwork-$timestamp.csv"
$jsonPath = Join-Path $OutputPath "ProcessNetwork-$timestamp.json"
$report | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
($report | ConvertTo-Json -Depth 5) | Set-Content -Path $jsonPath -Encoding UTF8
[pscustomobject]@{ State = $State; ConnectionCount = $report.Count; Csv = $csvPath; Json = $jsonPath; GeneratedAt = Get-Date }
