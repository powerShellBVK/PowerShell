#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(1, 365)]
    [int]$Days = 7,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Join-Path $env:USERPROFILE 'Desktop\Momentum-ClientReports')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') { throw 'Dieses Skript kann nur auf Windows-Clients ausgeführt werden.' }
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$cutoff = (Get-Date).AddDays(-$Days)
$tasks = @(Get-ScheduledTask -ErrorAction Stop)
$report = foreach ($task in $tasks) {
    try {
        $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop
        if ($info.LastRunTime -ge $cutoff -or $info.LastTaskResult -ne 0) {
            [pscustomobject]@{
                TaskName = $task.TaskName
                TaskPath = $task.TaskPath
                State = $task.State.ToString()
                LastRunTime = $info.LastRunTime
                NextRunTime = $info.NextRunTime
                LastTaskResult = $info.LastTaskResult
                NumberOfMissedRuns = $info.NumberOfMissedRuns
            }
        }
    } catch { Write-Verbose "Aufgabe übersprungen: $($task.TaskPath)$($task.TaskName)" }
}
$report = @($report | Sort-Object @{ Expression = 'LastTaskResult'; Descending = $true }, @{ Expression = 'LastRunTime'; Descending = $true })
$jsonPath = Join-Path $OutputPath "ScheduledTasks-$timestamp.json"
$csvPath = Join-Path $OutputPath "ScheduledTasks-$timestamp.csv"
$report | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8
$report | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
[pscustomobject]@{ Json = $jsonPath; Csv = $csvPath; TasksWithActivity = $report.Count; FailedTasks = @($report | Where-Object { $_.LastTaskResult -ne 0 }).Count; GeneratedAt = Get-Date }
