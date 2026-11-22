# IT Bridge: generate Flutter platform shells (windows/ and android/).
# Platform shells come from the Flutter toolchain, not handwritten files.
# Usage: powershell -ExecutionPolicy Bypass -File tools/bootstrap_platforms.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$temp = Join-Path $root '.toolchain\platform_bootstrap'
New-Item -ItemType Directory -Force -Path $temp | Out-Null

& flutter create --project-name itbridge_desktop --org com.itbridge --platforms windows --no-pub (Join-Path $temp 'desktop_shell')
$desktopTarget = Join-Path $root 'apps\itbridge_desktop\windows'
if (Test-Path $desktopTarget) { Remove-Item -Recurse -Force $desktopTarget }
Copy-Item -Recurse -Force (Join-Path $temp 'desktop_shell\windows') $desktopTarget

& flutter create --project-name itbridge_mobile --org com.itbridge --platforms android --no-pub (Join-Path $temp 'mobile_shell')
$androidTarget = Join-Path $root 'apps\itbridge_mobile\android'
if (Test-Path $androidTarget) { Remove-Item -Recurse -Force $androidTarget }
Copy-Item -Recurse -Force (Join-Path $temp 'mobile_shell\android') $androidTarget
Copy-Item -Force (Join-Path $root 'tools\gradle.properties') (Join-Path $androidTarget 'gradle.properties')

Write-Output 'Platform shells generated. Next: flutter pub get (windows then android, never in parallel).'
