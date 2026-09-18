# PowerShell Client Toolkit

Sammlung sicherer und praxisnaher PowerShell-Skripte für Windows-10- und Windows-11-Clients. Die Skripte sind für IT-Administratoren gedacht, arbeiten standardmäßig möglichst lesend und unterstützen bei Änderungen `-WhatIf`.

## Voraussetzungen

- Windows 10 oder Windows 11
- Windows PowerShell 5.1 oder PowerShell 7+
- Für Systemänderungen: PowerShell als Administrator starten
- Skriptausführung nur nach eigener Prüfung erlauben, zum Beispiel:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Die Skripte ändern keine Execution Policy automatisch.

## Enthaltene Skripte

### `Get-ClientHealthReport.ps1`

Erstellt einen lokalen HTML- und JSON-Bericht mit:

- Windows-Version und Computerinformationen
- Uptime und Laufwerken
- freiem Speicher
- wichtigen Diensten
- Windows Defender-Status
- Windows Update-Informationen
- kritischen Fehlern aus den letzten 24 Stunden

```powershell
.\Get-ClientHealthReport.ps1 -OutputPath C:\Reports
```

### `Get-SoftwareInventory.ps1`

Liest installierte Software aus den 32-Bit- und 64-Bit-Uninstall-Schlüsseln aus und exportiert CSV/JSON. Es wird nichts installiert oder entfernt.

```powershell
.\Get-SoftwareInventory.ps1 -OutputPath C:\Reports
```

### `Invoke-ClientCleanup.ps1`

Bereinigt temporäre Benutzer- und Systemdateien, leert den Windows-Update-Downloadcache und kann den Papierkorb leeren. Erst mit Vorschau testen:

```powershell
.\Invoke-ClientCleanup.ps1 -WhatIf
```

Ausführen:

```powershell
.\Invoke-ClientCleanup.ps1 -CleanUpdateCache -ClearRecycleBin
```

### `Test-ClientNetwork.ps1`

Prüft Adapter, IP-Konfiguration, DNS, Gateway, Internet und eine frei wählbare TCP-Verbindung. Mit `-RepairStack` können Winsock und TCP/IP zurückgesetzt werden; dieser Schritt erfordert einen Neustart.

```powershell
.\Test-ClientNetwork.ps1 -TargetName example.com -TargetPort 443
.\Test-ClientNetwork.ps1 -RepairStack -WhatIf
```

### `Get-LocalSecurityAudit.ps1`

Erstellt einen lokalen Sicherheitsbericht mit lokalen Benutzern, lokalen Administratoren, Firewall-Profilen, BitLocker-Status und Defender-Status. Das Skript verändert keine Einstellungen.

```powershell
.\Get-LocalSecurityAudit.ps1 -OutputPath C:\Reports
```

### `Get-EventLogSummary.ps1`

Sammelt Warnungen und Fehler aus System-, Application- und Security-Log mit `Get-WinEvent` und exportiert CSV/JSON.

```powershell
.\Get-EventLogSummary.ps1 -Days 2 -MaximumEvents 200 -OutputPath C:\Reports
```

### `Get-ProcessNetworkReport.ps1`

Ordnet aktive TCP-Verbindungen den verantwortlichen Prozessen zu. Das hilft bei verdächtigen Verbindungen, blockierten Ports und Support-Fällen.

```powershell
.\Get-ProcessNetworkReport.ps1 -State Established -OutputPath C:\Reports
.\Get-ProcessNetworkReport.ps1 -State Listen
```

### `Get-WindowsUpdateStatus.ps1`

Zeigt Update-Dienste, installierte Hotfixes und Windows-Update-Ereignisse. Mit `-IncludeAvailable` wird die eingebaute Windows-Update-Suche über die COM-API abgefragt; es wird kein Update automatisch installiert.

```powershell
.\Get-WindowsUpdateStatus.ps1 -IncludeAvailable -OutputPath C:\Reports
```

### `Get-PrinterHealth.ps1`

Prüft den Druckerwarteschlangendienst, installierte Drucker und offene Druckaufträge.

```powershell
.\Get-PrinterHealth.ps1 -PrinterName '*' -OutputPath C:\Reports
```

### `Repair-WindowsImage.ps1`

Führt standardmäßig nur eine Prüfung des Windows-Komponentenspeichers und optional eine SFC-Prüfung aus. Reparaturen sind ausdrücklich opt-in:

```powershell
.\Repair-WindowsImage.ps1 -WhatIf
.\Repair-WindowsImage.ps1 -RunSfc -WhatIf
.\Repair-WindowsImage.ps1 -Repair -RunSfc
```

`-Repair` und `-RunSfc` benötigen eine als Administrator gestartete PowerShell. DISM und SFC können lange laufen und sollten nicht während eines laufenden Wartungsfensters abgebrochen werden.

## Sicherheitshinweise

- Skripte zuerst mit `-WhatIf` oder auf einem Testclient ausführen.
- Reports können Gerätenamen, Benutzer, Software und Sicherheitsinformationen enthalten. Nicht ungeschützt weitergeben.
- Für zentrale Ausführung sollten Signierung, Intune, Configuration Manager, Gruppenrichtlinien oder ein kontrolliertes Management-System verwendet werden.
- Das Toolkit enthält bewusst keine automatischen Kennwortänderungen, keine Deaktivierung von Sicherheitssoftware und keine destruktiven Registry-Tweaks.
- Die neuen Reports basieren ausschließlich auf Windows-Bordmitteln wie `Get-WinEvent`, `Get-NetTCPConnection`, `Get-MpComputerStatus`, `Get-BitLockerVolume`, `Get-Volume`, `Get-Printer`, DISM und SFC.

## Microsoft-Dokumentation

- [`Get-WinEvent`](https://learn.microsoft.com/powershell/module/microsoft.powershell.diagnostics/get-winevent)
- [`Get-NetTCPConnection`](https://learn.microsoft.com/powershell/module/nettcpip/get-nettcpconnection)
- [`Get-MpComputerStatus`](https://learn.microsoft.com/powershell/module/defender/get-mpcomputerstatus)
- [`Get-BitLockerVolume`](https://learn.microsoft.com/powershell/module/bitlocker/get-bitlockervolume)
- [`Get-Volume`](https://learn.microsoft.com/powershell/module/storage/get-volume)

## Testen

Auf Windows lokal prüfen:

```powershell
Get-ChildItem *.ps1 | ForEach-Object { [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null) }
```

Zusätzlich empfiehlt sich PSScriptAnalyzer:

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser
Invoke-ScriptAnalyzer -Path . -Recurse
```

Auf macOS ohne PowerShell können die Skripte nicht vollständig ausgeführt werden. Die Windows-spezifischen Cmdlets und APIs müssen deshalb auf einem Testclient validiert werden.
