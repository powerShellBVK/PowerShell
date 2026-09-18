#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Join-Path $env:USERPROFILE 'Desktop\Momentum-ClientReports')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') { throw 'Dieses Skript kann nur auf Windows-Clients ausgeführt werden.' }
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$devices = @(Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction Stop | Select-Object Name, DeviceID, Status, ConfigManagerErrorCode, Manufacturer, PNPClass, Service)
$drivers = @(Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Select-Object DeviceName, DriverVersion, DriverDate, Manufacturer, InfName, IsSigned, Signer, Status, DeviceID)
$problemDevices = @($devices | Where-Object { ($_.ConfigManagerErrorCode -and $_.ConfigManagerErrorCode -ne 0) -or $_.Status -ne 'OK' })
$unsignedDrivers = @($drivers | Where-Object { $_.IsSigned -eq $false })
$report = [pscustomobject]@{
    GeneratedAt = (Get-Date).ToString('o')
    DeviceCount = $devices.Count
    ProblemDeviceCount = $problemDevices.Count
    UnsignedDriverCount = $unsignedDrivers.Count
    ProblemDevices = $problemDevices
    UnsignedDrivers = $unsignedDrivers
    Drivers = $drivers
}
$jsonPath = Join-Path $OutputPath "DeviceDriverHealth-$timestamp.json"
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8
[pscustomobject]@{ Json = $jsonPath; DeviceCount = $devices.Count; ProblemDeviceCount = $problemDevices.Count; UnsignedDriverCount = $unsignedDrivers.Count; GeneratedAt = Get-Date }
