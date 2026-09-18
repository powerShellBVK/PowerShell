#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter()]
    [switch]$Repair,
    [Parameter()]
    [switch]$RunSfc
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') { throw 'Dieses Skript kann nur auf Windows-Clients ausgeführt werden.' }

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) { throw 'Dieses Skript muss als Administrator ausgeführt werden.' }

$results = [System.Collections.Generic.List[object]]::new()
function Invoke-RepairCommand {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param([string]$FilePath, [string[]]$ArgumentList, [string]$Description)
    if ($PSCmdlet.ShouldProcess($Description, "$FilePath $($ArgumentList -join ' ')")) {
        $output = & $FilePath @ArgumentList 2>&1 | Out-String
        $results.Add([pscustomobject]@{ Command = "$FilePath $($ArgumentList -join ' ')"; ExitCode = $LASTEXITCODE; Output = $output.Trim() })
    } else {
        $results.Add([pscustomobject]@{ Command = "$FilePath $($ArgumentList -join ' ')"; ExitCode = $null; Output = 'WhatIf: nicht ausgeführt' })
    }
}

Invoke-RepairCommand -FilePath 'DISM.exe' -ArgumentList '/Online', '/Cleanup-Image', $(if ($Repair) { '/RestoreHealth' } else { '/ScanHealth' }) -Description 'Windows-Komponentenspeicher prüfen/reparieren'
if ($RunSfc) {
    Invoke-RepairCommand -FilePath 'sfc.exe' -ArgumentList $(if ($Repair) { '/scannow' } else { '/verifyonly' }) -Description 'Geschützte Systemdateien prüfen/reparieren'
}

$results
