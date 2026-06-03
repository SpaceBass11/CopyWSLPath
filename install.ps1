# CopyWslPath installer
# Installs per-user Explorer context-menu entries under HKCU.
# No admin required.

$ErrorActionPreference = "Stop"

$toolName = "CopyWslPath"
$menuText = "Copy WSL path"
$toolDir = Join-Path $env:LOCALAPPDATA "WSLTools"
$exePath = Join-Path $toolDir "$toolName.exe"
$sourcePath = Join-Path $PSScriptRoot "$toolName.cs"

Write-Host "Installing $toolName..."

if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Could not find source file: $sourcePath"
}

New-Item -ItemType Directory -Path $toolDir -Force | Out-Null

# Prefer 64-bit .NET Framework compiler, then fall back to 32-bit.
$cscCandidates = @(
    "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)
$csc = $cscCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $csc) {
    throw "Could not find csc.exe. Expected .NET Framework compiler under Windows Microsoft.NET Framework folders."
}

Write-Host "Compiling $toolName.exe..."
& $csc `
    /nologo `
    /target:winexe `
    /out:"$exePath" `
    /reference:System.Windows.Forms.dll `
    "$sourcePath"

if (-not (Test-Path -LiteralPath $exePath)) {
    throw "Compile failed. EXE was not created: $exePath"
}

function Set-ShellVerb {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VerbKey,
        [Parameter(Mandatory = $true)]
        [string]$ArgumentToken
    )

    New-Item -Path "$VerbKey\command" -Force | Out-Null
    Set-ItemProperty -Path $VerbKey -Name "MUIVerb" -Value $menuText
    Set-ItemProperty -Path $VerbKey -Name "Icon" -Value $exePath
    $command = "`"$exePath`" `"$ArgumentToken`""
    Set-Item -Path "$VerbKey\command" -Value $command
    Write-Host "Registered: $VerbKey"
    Write-Host "  $command"
}

# Files and folders.
Set-ShellVerb `
    -VerbKey "HKCU:\Software\Classes\AllFilesystemObjects\shell\CopyWSLPath" `
    -ArgumentToken "%1"

# Empty space inside normal folders.
# Use %V\. instead of %V to avoid quoted trailing-backslash breakage at roots.
Set-ShellVerb `
    -VerbKey "HKCU:\Software\Classes\Directory\Background\shell\CopyWSLPath" `
    -ArgumentToken "%V\."

# Empty space at drive roots like C:\ or D:\.
# Use %V\. instead of %V to avoid D:\" quote breakage.
Set-ShellVerb `
    -VerbKey "HKCU:\Software\Classes\Drive\Background\shell\CopyWSLPath" `
    -ArgumentToken "%V\."

# Right-clicking a drive icon in This PC.
Set-ShellVerb `
    -VerbKey "HKCU:\Software\Classes\Drive\shell\CopyWSLPath" `
    -ArgumentToken "%1"

Write-Host ""
Write-Host "Testing EXE with C:\Users..."
& $exePath "C:\Users"
$clip = Get-Clipboard
Write-Host "Clipboard now contains: $clip"

Write-Host ""
Write-Host "Restarting Explorer..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Installed successfully."
Write-Host "Right-click a file, folder, drive, or folder background and choose '$menuText'."
