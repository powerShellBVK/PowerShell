#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [switch]$Force,
    [Parameter()]
    [switch]$Wait
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') { throw 'Dieses Skript kann nur auf Windows-Clients ausgeführt werden.' }
$arguments = @()
if ($Force) { $arguments += '/force' }
if ($Wait) { $arguments += '/wait:30' }
if ($PSCmdlet.ShouldProcess('Lokaler Client', "Gruppenrichtlinien aktualisieren $arguments")) {
    $output = & gpupdate.exe $arguments 2>&1
    $exitCode = $LASTEXITCODE
    [pscustomobject]@{ ExitCode = $exitCode; Force = $Force.IsPresent; Wait = $Wait.IsPresent; Output = ($output -join [Environment]::NewLine); CompletedAt = Get-Date }
    if ($exitCode -ne 0) { throw "gpupdate.exe wurde mit ExitCode $exitCode beendet." }
} else {
    [pscustomobject]@{ ExitCode = $null; Force = $Force.IsPresent; Wait = $Wait.IsPresent; Output = 'WhatIf: nicht ausgeführt'; CompletedAt = Get-Date }
}
