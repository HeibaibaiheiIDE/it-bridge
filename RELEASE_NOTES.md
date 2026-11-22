# IT Bridge v1.0.0

跨设备文字消息与任意文件直连传输工具。MIT License，发布者/签名主体：**黑白白黑**。

## 发布文件

- `IT_Bridge_v1.0.0_x64_Setup.exe`：Inno Setup 6 生成的 Windows EXE 安装包，签名主体 `CN=黑白白黑`。位于 `D:\IT_Bridge\bin`，内含完整运行时、桌面/开始菜单快捷方式、卸载器和 Android APK。
- `IT_Bridge_v1.0.0_x64.msix`：Windows 安装包，Publisher `CN=黑白白黑`，自签名。
- `IT_Bridge_v1.0.0_x64_portable.zip`：完整 Windows 便携版；解压后双击 `IT_Bridge.exe`。已包含 `flutter_windows.dll`、`desktop_drop_plugin.dll`、`permission_handler_windows_plugin.dll` 与 `data/`。
- `IT_Bridge_v1.0.0_arm64.apk`：Android arm64-v8a 安装包，签名别名 `黑白白黑`，DN `CN=黑白白黑`。
- `SHA256SUMS.txt`：以上文件的 SHA-256。

本地可直接运行的目录：`D:\IT_Bridge\bin\IT_Bridge.exe`，同目录的 `IT_Bridge.apk` 为 Android 安装包。单独复制 exe 会报“找不到 DLL”，请使用完整目录或便携 zip。

## 功能

- Windows 三栏客户端、Android 五 Tab 客户端；统一私有二进制协议（TCP 34567 / UDP 34568）。
- 文字消息：UTF-8 JSON、64 KiB 单帧自动拆条、SEQ 去重、时间排序。
- 任意后缀文件：`.apk` / `.exe` / `.KSHBSISH` / 无后缀一律零改写；64 KiB 分块 `RandomAccessFile` 流式读写；SHA-256 校验；断点续传位图持久化。
- 设备列表、多会话，手机↔手机、电脑↔电脑、手机↔电脑。
- 实验性广域网：云中继、P2P/STUN、虚拟局域网、IPv6 直连；默认关闭，启用前需勾选免责声明。
- Dart 单文件中继服务器、邀请码配对、AES-256-GCM 端到端加密；中继仅见元数据与密文。
- Android 通知、前台服务、SAF 选文件、接收 APK 后系统安装。
- 图标由 `Android_IT.png` 转换，Windows ICO 与 Android mipmap 均已替换。

## 安装

- Windows MSIX：先安装 `certs/itbridge_msix.pfx` 到“受信任的根证书颁发机构/受信任人”，再安装 MSIX。
- Windows EXE：解压整个 Release 目录后运行 `IT_Bridge.exe`。
- Android APK：允许未知来源安装。

## 已知限制

- APK 仅 arm64-v8a。
- P2P 为 STUN 映射探测与直连尝试，未实现完整 TURN 协议；失败时回退云中继。
- 虚拟局域网依赖 Tailscale/ZeroTier 等外部工具先完成组网。
- 自签名证书需用户手动信任；正式发布请换成 CA 证书与上传密钥。
