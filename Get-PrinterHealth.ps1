#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter()]
    [string]$PrinterName = '*',
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = (Join-Path $env:USERPROFILE 'Desktop\Momentum-ClientReports')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') { throw 'Dieses Skript kann nur auf Windows-Clients ausgeführt werden.' }
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue
$printers = @(Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue | Select-Object Name, ComputerName, DriverName, PortName, PrinterStatus, PrinterState, Shared, Published)
$jobs = foreach ($printer in $printers) {
    Get-PrintJob -PrinterName $printer.Name -ErrorAction SilentlyContinue | Select-Object PrinterName, ID, DocumentName, UserName, SubmittedTime, JobStatus, Size
}
$report = [pscustomobject]@{
    GeneratedAt = (Get-Date).ToString('o')
    Spooler = [pscustomobject]@{ Status = if ($spooler) { $spooler.Status.ToString() } else { 'Nicht vorhanden' }; StartType = if ($spooler) { $spooler.StartType.ToString() } else { 'Unbekannt' } }
    Printers = $printers
    PrintJobs = @($jobs)
}
$jsonPath = Join-Path $OutputPath "PrinterHealth-$timestamp.json"
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8
[pscustomobject]@{ Json = $jsonPath; PrinterCount = $printers.Count; PrintJobCount = @($jobs).Count; GeneratedAt = Get-Date }
