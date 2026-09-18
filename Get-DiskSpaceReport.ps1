#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(1, 99)]
    [int]$MinimumFreePercent = 15,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Join-Path $env:USERPROFILE 'Desktop\Momentum-ClientReports')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') { throw 'Dieses Skript kann nur auf Windows-Clients ausgeführt werden.' }
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$volumes = @(Get-Volume -ErrorAction Stop | Where-Object { $_.DriveLetter -and $_.Size -gt 0 } | ForEach-Object {
    $freePercent = [math]::Round(($_.SizeRemaining / $_.Size) * 100, 1)
    [pscustomobject]@{
        Drive = "$($_.DriveLetter):"
        Label = $_.FileSystemLabel
        FileSystem = $_.FileSystem
        HealthStatus = $_.HealthStatus
        SizeGB = [math]::Round($_.Size / 1GB, 2)
        FreeGB = [math]::Round($_.SizeRemaining / 1GB, 2)
        FreePercent = $freePercent
        LowSpace = $freePercent -lt $MinimumFreePercent
    }
})
$jsonPath = Join-Path $OutputPath "DiskSpace-$timestamp.json"
$csvPath = Join-Path $OutputPath "DiskSpace-$timestamp.csv"
$volumes | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8
$volumes | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
[pscustomobject]@{ Json = $jsonPath; Csv = $csvPath; LowSpaceVolumes = @($volumes | Where-Object LowSpace).Count; ThresholdPercent = $MinimumFreePercent; GeneratedAt = Get-Date }
