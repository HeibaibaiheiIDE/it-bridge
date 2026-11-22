# IT Bridge: reproducible serial Release build (exe -> MSIX -> apk).
# Strictly serial to protect the 4GB RAM development machine.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sdkFlutter = Join-Path $root '.toolchain\sdk\flutter\bin'
$pubCache = Join-Path $root '.toolchain\pub-cache'
$jdk = Join-Path $root '.toolchain\jdk17\jdk-17.0.21.1+2'
$androidSdk = 'E:\Android\Sdk'
$msixPfx = Join-Path $root 'certs\itbridge_msix.pfx'
$msixPassword = 'itbridge2026'
$signtool = 'C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe'

$env:JAVA_HOME = $jdk
$env:PATH = "$jdk\bin;$sdkFlutter;$env:PATH"
$env:PUB_CACHE = $pubCache
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
$env:PUB_HOSTED_URL = 'https://pub.dev'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:ANDROID_HOME = $androidSdk
$env:ANDROID_SDK_ROOT = $androidSdk

Write-Output 'Step 1/6: regenerate icons'
python (Join-Path $root 'tools\make_icons.py')

Write-Output 'Step 2/6: build Windows exe'
Push-Location (Join-Path $root 'apps\itbridge_desktop')
try {
  & flutter build windows --release
  if ($LASTEXITCODE -ne 0) { throw 'Windows build failed' }
} finally { Pop-Location }

Write-Output 'Step 3/6: sign exe with CN=黑白白黑'
$exe = Join-Path $root 'apps\itbridge_desktop\build\windows\x64\runner\Release\IT_Bridge.exe'
if (Test-Path $signtool) {
  & $signtool sign /fd SHA256 /f $msixPfx /p $msixPassword $exe
}

Write-Output 'Step 4/6: create signed MSIX installer'
Push-Location (Join-Path $root 'apps\itbridge_desktop')
try {
  $dart = Join-Path $root '.toolchain\sdk\flutter\bin\cache\dart-sdk\bin\dart.exe'
  & $dart run msix:create --install-certificate false --certificate-path $msixPfx --certificate-password $msixPassword --publisher 'CN=黑白白黑'
  if ($LASTEXITCODE -ne 0) { throw 'MSIX build failed' }
} finally { Pop-Location }

Write-Output 'Step 5/6: build signed Android apk (arm64)'
Push-Location (Join-Path $root 'apps\itbridge_mobile')
try {
  & flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
  if ($LASTEXITCODE -ne 0) { throw 'Android build failed' }
} finally { Pop-Location }

Write-Output 'Step 6/6: package complete runtime into bin/ and release/'
& (Join-Path $root 'tools\package_release.ps1')
