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

## Sicherheitshinweise

- Skripte zuerst mit `-WhatIf` oder auf einem Testclient ausführen.
- Reports können Gerätenamen, Benutzer, Software und Sicherheitsinformationen enthalten. Nicht ungeschützt weitergeben.
- Für zentrale Ausführung sollten Signierung, Intune, Configuration Manager, Gruppenrichtlinien oder ein kontrolliertes Management-System verwendet werden.
- Das Toolkit enthält bewusst keine automatischen Kennwortänderungen, keine Deaktivierung von Sicherheitssoftware und keine destruktiven Registry-Tweaks.

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
