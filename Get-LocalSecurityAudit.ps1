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
$localUsers = @(Get-LocalUser -ErrorAction SilentlyContinue | Select-Object Name, Enabled, LastLogon, PasswordRequired, PasswordNeverExpires, UserMayChangePassword)
$localAdmins = @(Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue | Select-Object Name, ObjectClass, PrincipalSource)
$firewall = @(Get-NetFirewallProfile -ErrorAction SilentlyContinue | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction, LogBlocked)
$bitlocker = @(Get-BitLockerVolume -ErrorAction SilentlyContinue | Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionMethod, EncryptionPercentage)
$defender = $null
try {
    $defender = Get-MpComputerStatus -ErrorAction Stop | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, IoavProtectionEnabled, NISEnabled, AntivirusSignatureLastUpdated
} catch { $defender = [pscustomobject]@{ Status = 'Nicht verfügbar' } }

$audit = [pscustomobject]@{
    GeneratedAt = (Get-Date).ToString('o')
    ComputerName = $env:COMPUTERNAME
    LocalUsers = $localUsers
    LocalAdministrators = $localAdmins
    FirewallProfiles = $firewall
    BitLockerVolumes = $bitlocker
    Defender = $defender
}

$jsonPath = Join-Path $OutputPath "SecurityAudit-$timestamp.json"
$htmlPath = Join-Path $OutputPath "SecurityAudit-$timestamp.html"
$audit | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8
$audit | ConvertTo-Html -Title "Security Audit - $env:COMPUTERNAME" -PreContent "<h1>Local Security Audit</h1><p>Erstellt: $(Get-Date)</p>" | Set-Content -Path $htmlPath -Encoding UTF8

[pscustomobject]@{ Json = $jsonPath; Html = $htmlPath; Computer = $env:COMPUTERNAME; GeneratedAt = Get-Date }
