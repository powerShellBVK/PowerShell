#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [switch]$CleanUpdateCache,
    [Parameter()]
    [switch]$ClearRecycleBin,
    [Parameter()]
    [ValidateRange(1, 3650)]
    [int]$TempFileAgeDays = 7
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'Dieses Skript kann nur auf Windows-Clients ausgeführt werden.'
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$adminRequired = $CleanUpdateCache
if ($adminRequired -and -not (Test-IsAdministrator)) {
    throw 'Für -CleanUpdateCache muss PowerShell als Administrator ausgeführt werden.'
}

$locations = @($env:TEMP, "$env:WINDIR\Temp") | Where-Object { Test-Path $_ } | Select-Object -Unique
$cutoff = (Get-Date).AddDays(-$TempFileAgeDays)
$removedFiles = 0
$removedBytes = 0

foreach ($location in $locations) {
    $files = Get-ChildItem -LiteralPath $location -File -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoff }
    foreach ($file in $files) {
        if ($PSCmdlet.ShouldProcess($file.FullName, 'Temporäre Datei entfernen')) {
            try {
                $removedBytes += $file.Length
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                $removedFiles++
            } catch { Write-Verbose "Übersprungen: $($file.FullName) ($($_.Exception.Message))" }
        }
    }
}

if ($CleanUpdateCache) {
    $services = 'bits', 'wuauserv', 'cryptsvc'
    foreach ($serviceName in $services) {
        if ($PSCmdlet.ShouldProcess($serviceName, 'Windows-Update-Dienst stoppen')) {
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        }
    }
    $downloadPath = Join-Path $env:WINDIR 'SoftwareDistribution\Download'
    if ($PSCmdlet.ShouldProcess($downloadPath, 'Windows-Update-Downloadcache leeren')) {
        Remove-Item -LiteralPath (Join-Path $downloadPath '*') -Recurse -Force -ErrorAction SilentlyContinue
    }
    foreach ($serviceName in $services) {
        if ($PSCmdlet.ShouldProcess($serviceName, 'Windows-Update-Dienst starten')) {
            Start-Service -Name $serviceName -ErrorAction SilentlyContinue
        }
    }
}

if ($ClearRecycleBin) {
    if ($PSCmdlet.ShouldProcess('Alle lokalen Papierkörbe', 'Papierkorb leeren')) {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    }
}

[pscustomobject]@{
    RemovedFiles = $removedFiles
    FreedMB = [math]::Round($removedBytes / 1MB, 2)
    UpdateCacheRequested = $CleanUpdateCache.IsPresent
    RecycleBinRequested = $ClearRecycleBin.IsPresent
    WhatIf = [bool]$WhatIfPreference
    CompletedAt = Get-Date
}
