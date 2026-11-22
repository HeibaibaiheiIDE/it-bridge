#define MyAppName "IT Bridge"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "黑白白黑"
#define MyAppExeName "IT_Bridge.exe"
#define MySetupName "IT_Bridge_v1.0.0_x64_Setup"

[Setup]
AppId={{8C7D9E1B-6F2A-4B5D-9C0E-1A2B3C4D5E6F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\IT Bridge
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=D:\IT_Bridge\LICENSE
OutputDir=D:\IT_Bridge\bin
OutputBaseFilename={#MySetupName}
SetupIconFile=D:\IT_Bridge\apps\itbridge_desktop\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
ShowLanguageDialog=no
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} installer
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}
VersionInfoVersion={#MyAppVersion}

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Default.isl,D:\IT_Bridge\tools\installer\ChineseSimplifiedCustom.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "D:\IT_Bridge\bin\IT_Bridge.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\IT_Bridge\bin\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\IT_Bridge\bin\desktop_drop_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\IT_Bridge\bin\permission_handler_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\IT_Bridge\bin\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "D:\IT_Bridge\bin\IT_Bridge.apk"; DestDir: "{app}\Android"; DestName: "IT_Bridge_v1.0.0_arm64.apk"; Flags: ignoreversion
Source: "D:\IT_Bridge\LICENSE"; DestDir: "{app}\docs"; DestName: "LICENSE.txt"; Flags: ignoreversion
Source: "D:\IT_Bridge\RELEASE_NOTES.md"; DestDir: "{app}\docs"; DestName: "RELEASE_NOTES.md"; Flags: ignoreversion
Source: "D:\IT_Bridge\bin\README.txt"; DestDir: "{app}"; DestName: "README.txt"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
