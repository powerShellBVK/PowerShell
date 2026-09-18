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
$computer = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$bios = Get-CimInstance Win32_BIOS
$drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    [pscustomobject]@{
        Drive = $_.DeviceID
        SizeGB = [math]::Round($_.Size / 1GB, 2)
        FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
        FreePercent = if ($_.Size) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } else { 0 }
    }
}

$serviceNames = 'wuauserv', 'bits', 'WinDefend', 'MpsSvc'
$services = foreach ($name in $serviceNames) {
    $service = Get-Service -Name $name -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Name = $name
        Status = if ($service) { $service.Status.ToString() } else { 'Nicht vorhanden' }
        StartType = if ($service) { $service.StartType.ToString() } else { 'Unbekannt' }
    }
}

$defender = $null
try { $defender = Get-MpComputerStatus -ErrorAction Stop } catch { }
$updates = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 HotFixID, Description, InstalledOn
$events = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2; StartTime = (Get-Date).AddHours(-24) } -MaxEvents 100 -ErrorAction SilentlyContinue | Select-Object -First 25 TimeCreated, Id, ProviderName, LevelDisplayName, Message
$uptime = (Get-Date) - $os.LastBootUpTime

$report = [pscustomobject]@{
    GeneratedAt = (Get-Date).ToString('o')
    Computer = [pscustomobject]@{
        Name = $env:COMPUTERNAME
        Manufacturer = $computer.Manufacturer
        Model = $computer.Model
        SerialNumber = $bios.SerialNumber
        User = $env:USERNAME
        MemoryGB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
    }
    OperatingSystem = [pscustomobject]@{
        Caption = $os.Caption
        Version = $os.Version
        Build = $os.BuildNumber
        Architecture = $os.OSArchitecture
        LastBoot = $os.LastBootUpTime
        UptimeHours = [math]::Round($uptime.TotalHours, 1)
    }
    Drives = @($drives)
    Services = @($services)
    Defender = if ($defender) { [pscustomobject]@{ AntivirusEnabled = $defender.AntivirusEnabled; RealTimeProtection = $defender.RealTimeProtectionEnabled; SignatureAgeDays = $defender.AntivirusSignatureAge; QuickScanAgeDays = $defender.QuickScanAge } } else { 'Nicht verfügbar' }
    RecentHotFixes = @($updates)
    CriticalSystemEvents = @($events)
}

$jsonPath = Join-Path $OutputPath "ClientHealth-$timestamp.json"
$htmlPath = Join-Path $OutputPath "ClientHealth-$timestamp.html"
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8
$report | ConvertTo-Html -Title "Client Health Report - $env:COMPUTERNAME" -PreContent "<h1>Client Health Report</h1><p>Erstellt: $(Get-Date)</p>" | Set-Content -Path $htmlPath -Encoding UTF8

[pscustomobject]@{ Json = $jsonPath; Html = $htmlPath; Computer = $env:COMPUTERNAME; GeneratedAt = Get-Date }
