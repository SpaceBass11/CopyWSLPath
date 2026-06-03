# CopyWslPath uninstaller
# Removes per-user Explorer context-menu entries and the compiled EXE.

$ErrorActionPreference = "Stop"

$toolName = "CopyWslPath"
$toolDir = Join-Path $env:LOCALAPPDATA "WSLTools"
$exePath = Join-Path $toolDir "$toolName.exe"

Write-Host "Uninstalling $toolName..."

$keys = @(
    "HKCU:\Software\Classes\AllFilesystemObjects\shell\CopyWSLPath",
    "HKCU:\Software\Classes\Directory\Background\shell\CopyWSLPath",
    "HKCU:\Software\Classes\Drive\Background\shell\CopyWSLPath",
    "HKCU:\Software\Classes\Drive\shell\CopyWSLPath"
)

foreach ($key in $keys) {
    Remove-Item -LiteralPath $key -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed: $key"
}

Remove-Item -LiteralPath $exePath -Force -ErrorAction SilentlyContinue
Write-Host "Removed EXE: $exePath"

# Leave the WSLTools directory if other things exist in it.
try {
    $remaining = Get-ChildItem -LiteralPath $toolDir -Force -ErrorAction SilentlyContinue
    if (-not $remaining) {
        Remove-Item -LiteralPath $toolDir -Force -ErrorAction SilentlyContinue
        Write-Host "Removed empty tool directory: $toolDir"
    }
}
catch {
    # Non-fatal.
}

Write-Host ""
Write-Host "Restarting Explorer..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Uninstalled successfully."
