# CopyWslPath

Adds a Windows Explorer right-click menu item called **Copy WSL path**.

It copies Windows paths like:

```text
C:\Users\me\Projects\Test
```

as WSL paths like:

```text
/mnt/c/Users/me/Projects/Test
```

It works without launching WSL and without flashing a PowerShell or CMD window.

## What it supports

* Right-click files
* Right-click folders
* Right-click empty space inside folders
* Right-click empty space at drive roots like `C:\` or `D:\`
* Right-click drive icons

## Why this exists

Windows/WSL has `wslpath`, but Explorer does not provide a simple built-in **Copy WSL path** context-menu item.

This tool avoids fragile context-menu one-liners like:

```text
mshta vbscript:CreateObject(...)
powershell.exe -Command ...
wsl.exe wslpath ...
```

Instead, it compiles a tiny no-window C# executable and registers it under `HKCU`.

## Install

Open **normal PowerShell**, not admin, from the repo folder:

```powershell
.\install.ps1
```

Restarting Explorer is handled by the installer.

## Uninstall

```powershell
.\uninstall.ps1
```

## Registry locations used

The installer writes to:

```text
HKCU\Software\Classes\AllFilesystemObjects\shell\CopyWSLPath
HKCU\Software\Classes\Directory\Background\shell\CopyWSLPath
HKCU\Software\Classes\Drive\Background\shell\CopyWSLPath
HKCU\Software\Classes\Drive\shell\CopyWSLPath
```

Command mapping:

```text
AllFilesystemObjects\shell\CopyWSLPath\command
  "CopyWslPath.exe" "%1"
Directory\Background\shell\CopyWSLPath\command
  "CopyWslPath.exe" "%V\."
Drive\Background\shell\CopyWSLPath\command
  "CopyWslPath.exe" "%V\."
Drive\shell\CopyWSLPath\command
  "CopyWslPath.exe" "%1"
```

The `%V\.` part is intentional.

At drive roots like `D:\`, passing plain `"%V"` can result in a broken argument such as:

```text
D:"
```

because the trailing backslash can interfere with the closing quote. Passing `"%V\."` results in:

```text
D:\.
```

which normalizes correctly to:

```text
/mnt/d
```

## Output examples

| Windows path           | Clipboard result           |
| ---------------------- | -------------------------- |
| `C:\Users`             | `/mnt/c/Users`             |
| `C:\Users\me\file.txt` | `/mnt/c/Users/me/file.txt` |
| `D:\`                  | `/mnt/d`                   |
| `D:\Games`             | `/mnt/d/Games`             |

## Notes

This intentionally handles normal Windows drive paths itself instead of calling `wsl.exe wslpath`.

That makes it faster and avoids issues where WSL cold-starts, hangs, or has automount problems.

UNC paths are not converted to `/mnt/...`; they are simply normalized with forward slashes.
