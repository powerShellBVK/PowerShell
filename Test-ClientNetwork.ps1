#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter()]
    [string]$TargetName = 'www.microsoft.com',
    [Parameter()]
    [ValidateRange(1, 65535)]
    [int]$TargetPort = 443,
    [Parameter()]
    [switch]$RepairStack
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

$adapters = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress)
$ipConfiguration = @(Get-NetIPConfiguration -ErrorAction SilentlyContinue | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer)
$dns = @(Resolve-DnsName -Name $TargetName -ErrorAction SilentlyContinue | Select-Object -First 5 Name, Type, IPAddress)
$ping = Test-Connection -ComputerName $TargetName -Count 2 -Quiet -ErrorAction SilentlyContinue
$tcp = Test-NetConnection -ComputerName $TargetName -Port $TargetPort -InformationLevel Quiet -WarningAction SilentlyContinue

if ($RepairStack) {
    if (-not (Test-IsAdministrator)) {
        throw 'Für -RepairStack muss PowerShell als Administrator ausgeführt werden.'
    }
    if ($PSCmdlet.ShouldProcess('Winsock und TCP/IP', 'Netzwerkstack zurücksetzen')) {
        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null
        Write-Warning 'Der Netzwerkstack wurde zurückgesetzt. Ein Neustart wird empfohlen.'
    }
}

[pscustomobject]@{
    GeneratedAt = Get-Date
    Target = $TargetName
    TargetPort = $TargetPort
    AdapterCount = $adapters.Count
    Adapters = $adapters
    IPConfiguration = $ipConfiguration
    DNSResults = $dns
    PingSucceeded = [bool]$ping
    TcpSucceeded = [bool]$tcp
    RepairRequested = $RepairStack.IsPresent
    RestartRecommended = [bool]$RepairStack
}
