#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Join-Path $env:USERPROFILE 'Desktop\Momentum-ClientReports')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'Dieses Skript kann nur auf Windows-Clients ausgeführt werden.'
}

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$paths = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

$inventory = foreach ($path in $paths) {
    Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | ForEach-Object {
        [pscustomobject]@{
            Name = [string]$_.DisplayName
            Version = [string]$_.DisplayVersion
            Publisher = [string]$_.Publisher
            InstallDate = [string]$_.InstallDate
            InstallLocation = [string]$_.InstallLocation
            UninstallString = [string]$_.UninstallString
            RegistryPath = $_.PSPath
        }
    }
}

$inventory = @($inventory | Sort-Object Name, Version -Unique)
$csvPath = Join-Path $OutputPath "SoftwareInventory-$timestamp.csv"
$jsonPath = Join-Path $OutputPath "SoftwareInventory-$timestamp.json"
$inventory | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
$inventory | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8

[pscustomobject]@{ Count = $inventory.Count; Csv = $csvPath; Json = $jsonPath; GeneratedAt = Get-Date }
