#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$TaskName = 'Momentum Client Health Report',
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ScriptPath = (Join-Path $PSScriptRoot 'Get-ClientHealthReport.ps1'),
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ReportPath = (Join-Path $env:ProgramData 'Momentum\ClientReports'),
    [Parameter()]
    [ValidateSet('Daily', 'Weekly')]
    [string]$Frequency = 'Weekly',
    [Parameter()]
    [ValidateRange(0, 23)]
    [int]$Hour = 8
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') { throw 'Dieses Skript kann nur auf Windows-Clients ausgeführt werden.' }
if (-not (Test-Path -LiteralPath $ScriptPath)) { throw "Health-Report nicht gefunden: $ScriptPath" }
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Die geplante Aufgabe muss als Administrator registriert werden.' }

$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" -OutputPath `"$ReportPath`""
$trigger = if ($Frequency -eq 'Daily') { New-ScheduledTaskTrigger -Daily -At ([datetime]::Today.AddHours($Hour)) } else { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At ([datetime]::Today.AddHours($Hour)) }
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)

if ($PSCmdlet.ShouldProcess($TaskName, "Geplante Health-Report-Aufgabe registrieren")) {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description 'Erstellt regelmäßig einen Momentum Windows-Client-Health-Report.' -User 'SYSTEM' -RunLevel Highest -Force | Out-Null
    [pscustomobject]@{ TaskName = $TaskName; Frequency = $Frequency; Hour = $Hour; ScriptPath = $ScriptPath; ReportPath = $ReportPath; RegisteredAt = Get-Date }
} else {
    [pscustomobject]@{ TaskName = $TaskName; Frequency = $Frequency; Hour = $Hour; ScriptPath = $ScriptPath; ReportPath = $ReportPath; RegisteredAt = Get-Date; WhatIf = $true }
}
