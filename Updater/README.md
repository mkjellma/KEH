# KEH Updater

KEH Updater is a small Windows Forms application that installs the latest Kjellman ESO Helper release from GitHub.

## Build

```powershell
dotnet publish KEHUpdater.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```

The self-contained executable is written to:

`bin/Release/net8.0-windows/win-x64/publish/KEH-Updater.exe`

## Safety

- Updates are blocked while `eso64.exe` is running.
- The downloaded archive must contain `KjellmanESOHelper/KjellmanESOHelper.txt`.
- The manifest version must match the GitHub release version.
- Existing addon files are moved into `AddOns/KEH Backups` before installation.
- A failed folder swap restores the previous addon automatically.
- Backups are limited to the five newest successful updates.
