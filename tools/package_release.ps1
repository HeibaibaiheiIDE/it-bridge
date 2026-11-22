# Package the COMPLETE Windows runtime, not just the bare exe.
# Run after Windows + Android Release builds are available.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = 'v1.0.0'
$windowsRuntime = Join-Path $root 'apps\itbridge_desktop\build\windows\x64\runner\Release'
$apkSource = Join-Path $root 'apps\itbridge_mobile\build\app\outputs\flutter-apk\app-release.apk'
$msixSource = Join-Path $windowsRuntime 'itbridge_desktop.msix'
$release = Join-Path $root 'release'
$bin = Join-Path $root 'bin'
$portableDir = Join-Path $release ('IT_Bridge_' + $version + '_x64_portable')
$portableZip = Join-Path $release ('IT_Bridge_' + $version + '_x64_portable.zip')
$apkName = 'IT_Bridge_' + $version + '_arm64.apk'
$msixName = 'IT_Bridge_' + $version + '_x64.msix'

foreach ($required in @($windowsRuntime, $apkSource)) {
  if (-not (Test-Path $required)) { throw ('Missing build output: ' + $required) }
}

New-Item -ItemType Directory -Force -Path $release | Out-Null
New-Item -ItemType Directory -Force -Path $bin | Out-Null

if (Test-Path $portableDir) { Remove-Item $portableDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $portableDir | Out-Null

$runtimeFiles = Get-ChildItem -Path $windowsRuntime -File | Where-Object { $_.Name -ne 'itbridge_desktop.msix' }
$runtimeFiles | Copy-Item -Destination $portableDir -Force
Copy-Item -Path (Join-Path $windowsRuntime 'data') -Destination $portableDir -Recurse -Force

# Replace only known generated entries in bin, leaving any user files untouched.
$generatedNames = @('IT_Bridge.exe', 'flutter_windows.dll', 'desktop_drop_plugin.dll', 'permission_handler_windows_plugin.dll', 'data', 'IT_Bridge.apk', 'README.txt')
foreach ($name in $generatedNames) {
  Remove-Item -Path (Join-Path $bin $name) -Recurse -Force -ErrorAction SilentlyContinue
}

Copy-Item -Path (Join-Path $portableDir '*') -Destination $bin -Recurse -Force
Copy-Item -Path $apkSource -Destination (Join-Path $bin 'IT_Bridge.apk') -Force
"IT Bridge $version`r`nRun: double-click IT_Bridge.exe`r`nAndroid: IT_Bridge.apk" |
  Set-Content -Encoding ascii -Path (Join-Path $bin 'README.txt')

if (Test-Path $msixSource) {
  Copy-Item -Path $msixSource -Destination (Join-Path $release $msixName) -Force
}
Copy-Item -Path $apkSource -Destination (Join-Path $release $apkName) -Force

# The bare exe was the cause of the missing-DLL bug; keep only the complete portable package.
Remove-Item -Path (Join-Path $release ('IT_Bridge_' + $version + '_x64.exe')) -Force -ErrorAction SilentlyContinue

if (Test-Path $portableZip) { Remove-Item $portableZip -Force }
Compress-Archive -Path (Join-Path $portableDir '*') -DestinationPath $portableZip -CompressionLevel Optimal

Get-ChildItem -Path $release -File | Where-Object { $_.Name -ne 'SHA256SUMS.txt' } | ForEach-Object {
  $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
  "$hash  $($_.Name)"
} | Set-Content -Encoding ascii -Path (Join-Path $release 'SHA256SUMS.txt')

Write-Output ('BIN=' + $bin)
Get-ChildItem -Path $bin -Force | Select-Object Name, Length | Format-Table -AutoSize
Write-Output ('RELEASE=' + $release)
Get-ChildItem -Path $release -File | Select-Object Name, Length | Format-Table -AutoSize
