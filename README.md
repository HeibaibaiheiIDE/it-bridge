# IT Bridge — v1.0.0（M1–M7 全部完成）

> 当前进度：**M1–M7 已完成并编译发布产物**。
> Windows/MSIX/Android 均已用“黑白白黑”证书/别名签名；MIT License。

## 新版交付物

- `bin/IT_Bridge_v1.0.0_x64_Setup.exe`：Inno Setup 6 生成的 Windows EXE 安装包，签名主体 `CN=黑白白黑`。
- `bin/IT_Bridge.exe`：可直接双击运行的 Windows 主程序（同目录含 `flutter_windows.dll`、插件 DLL、`data/`）。
- `bin/IT_Bridge.apk`：可安装的 Android arm64-v8a 包（签名别名=黑白白黑）。
- `release/IT_Bridge_v1.0.0_x64_portable.zip`：完整便携版，解压后双击 `IT_Bridge.exe`。
- `release/IT_Bridge_v1.0.0_x64.msix`：Windows 安装包，Publisher=CN=黑白白黑。
- `release/IT_Bridge_v1.0.0_arm64.apk`、`release/SHA256SUMS.txt`。
- `RELEASE_NOTES.md`、`.github/workflows/release.yml`。
- `docs/RELAY_DEPLOYMENT.md`、`docs/TEST_CHECKLIST.md`。

> 修复说明：早期 `release/IT_Bridge_v1.0.0_x64.exe` 是单独文件，缺少 `flutter_windows.dll` 与 `desktop_drop_plugin.dll`，双击会报“找不到 DLL”。现已改为完整运行时目录/压缩包，`bin/` 就是可直接运行的目录。

## M2–M7 已落地能力

- Windows 1080×720 三栏 UI、气泡、文件卡片、右键菜单、拖拽发送、Enter/Shift+Enter。
- Android 五 Tab、聊天页、九宫格、SAF 选文件、通知、前台服务、APK 安装按钮。
- 文件流式传输、64 KiB 分块、SHA-256 校验、断点续传位图持久化。
- UDP 局域网发现、设备列表、多会话、手机↔手机/电脑↔电脑/手机↔电脑。
- 设置页免责声明、云中继/P2P(STUN)/虚拟局域网/IPv6 策略链。
- Dart 单文件中继服务器、邀请码配对、AES-256-GCM 端到端加密。
- 一键串行构建脚本 `tools/build_release.ps1`，含图标转换、签名、MSIX、APK、SHA-256；`tools/package_release.ps1` 单独负责把完整运行时打包到 `bin/` 与 `release/`。

已知限制：P2P 实现 STUN 映射探测与直连尝试，完整 TURN 协议未内置，失败时回退云中继；详见 `docs/TEST_CHECKLIST.md`。

---

## 0. 本机环境实测结论（2026-11-14）

| 项 | 实测 | 结论 |
| --- | --- | --- |
| OS / 内存 | Win10 Pro 22H2，总 4,074,596 KB，实测空闲约 884 MB | 4GB 约束成立，必须串行构建 |
| Dart / Flutter | 系统 PATH 中**未安装** | 已在 `.toolchain/sdk/flutter` 放一份 Flutter 3.24.5 / Dart 3.5.4（`.gitignore` 忽略），仅用于本机验证 |
| Java | `1.8.0_181` | AGP 8.x 需 **JDK 17**，M7 打包前必须安装并设 `JAVA_HOME` |
| Android SDK / VS C++ 工作负载 | 未检测到 | M7 打包前必须安装 |
| 网络 | `storage.googleapis.com` 的 GET 超时；`storage.flutter-io.cn` / `pub.dev` 可用 | 需设 `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` |
| 图标 | 已复制 `assets/Android_IT.png`（1080×900 PNG，15,854 B） | M7 做 ico / mipmap 转换 |

本机验证脚本与 SDK 放在 `.toolchain/`，**不是交付物**。

---

## 1. 规格冲突与替代方案（不擅自改协议 / 不换语言）

| # | 冲突 | 影响 | 替代方案（待确认项已标注） |
| --- | --- | --- | --- |
| C1 | `ByteData.view(..., Endian.little)` **不是合法 Dart API**：签名是 `ByteData.view(ByteBuffer, offsetInBytes, [length])`，无 endian 参数 | 无法按字面实现 | 用 `ByteData.view(...)` + 每个 `setUint16/32(v, Endian.little)` / `getUint16/32(Endian.little)` 显式指定。已实现，并有小端字节序断言。协议字节布局**不变** |
| C2 | `crypto` 包**不含 CRC32**，也**不含 AES-256-GCM** | M1 校验、M6 加密 | CRC32：core 内纯 Dart 查表流式实现（256 项表 = 1 KiB），已交付。AES-256-GCM：方案 A 新增纯 Dart 依赖 `pointycastle`（不引云服务/IM SDK）；方案 B 在 core 内自研 AES+GCM（审计风险高）。**建议 A，M6 前请确认加依赖** |
| C3 | 规格未定义 `ACK/ERROR` 负载、`DISCOVER(0x30)` 的 UDP 数据报格式 | 互操作性 | 已定义 `ACK/ERROR` 为 `{ackSeq, code, msg}`（不改变 TYPE/帧头）。UDP 建议**复用同一 20 字节帧作为单个数据报**，负载 ≤512 B 避免 IP 分片；M4/M5 落地，**请确认** |
| C4 | `FILE_CHUNK` 的 `offset` 只有 4 字节 → 单个 `fileId` 上限 `0xFFFFFFFF`（4 GiB - 1），与「传任意文件」中的超大文件冲突 | M3 大文件 | 方案 A：按 4 GiB 边界分配多个 `fileId`，接收端顺序拼接（协议字段不变，推荐）；方案 B：发送前预检拒绝并回 `ERROR 2004` 提示分卷。**M3 前请选一个** |
| C5 | Flutter 平台目录 `windows/`、`android/`（Gradle wrapper、runner、CMake 等）由工具链生成，无法手写「每个文件的代码」 | 交付形态 | 提供 `tools/bootstrap_platforms.ps1`（`flutter create` → 拷贝平台壳 → 覆盖 `gradle.properties`）；手写交付的是 `AndroidManifest.xml`、`file_paths.xml`、`gradle.properties`、图标引用等（M3/M7）。**请确认接受平台壳由工具生成** |
| C6 | 桌面「拖拽发送」需 `desktop_drop` 或 Windows `WM_DROPFILES` 平台通道；通知需 `flutter_local_notifications`；前台服务需 `flutter_foreground_task` 或 Kotlin Service；相册/拍照/位置需 `image_picker`/`geolocator`。均不在锁定依赖清单内，且与「语言 Dart」锁定部分冲突 | M2/M3 UI 细节 | 方案 A：新增这些纯插件依赖（需确认放宽依赖清单）；方案 B：写少量 Kotlin/C++ 平台通道（需确认放宽「语言 Dart」）；方案 C（当前默认，保证 M1/M2 可编译）：先用 `file_picker` 文件按钮 + 置灰项，拖拽/通知/前台服务在对应里程碑前逐项确认 |
| C7 | Android 10+ 分区存储下，「公共下载/ITBridge/」无法用纯 Dart + 锁定依赖直接写入 | M3 接收目录 | 方案 A：默认写应用专属外部目录 `getExternalStorageDirectory()/ITBridge/`，UI 提供 SAF「另存为」导出到公共下载；方案 B：Kotlin MediaStore 平台通道严格落到公共 `Download/ITBridge/`（需确认放宽「语言 Dart」）。**M3 前请选一个** |
| C8 | `shared_preferences` 是 Flutter 插件，纯 Dart core 不能依赖 | M5 免责声明记录 | 免责声明记录放在 apps 层；core 只提供 `DeviceIdStore` 这类纯 Dart 存储接口，目录由 apps 用 `path_provider` 解析后传入 |
| C9 | 里程碑 M6 才做邀请码配对，但 M1 就要定义 `0x03/0x04` 与 FLAGS bit1；且需回 `ERROR 1001 未配对` | 会话状态 | M1 由 `HELLO/HELLO_ACK` 建立会话，握手完成前的非 HELLO 帧回 `1001`；`PAIR_REQ/PAIR_RESP` 与 `encrypted` 位常量已保留但 M1 不启用，M6 在 `PeerSession` 上扩展。**协议不变** |
| C10 | 同一进程/同一台机器双开时 TCP 34567 端口独占 | 电脑↔电脑 单机联调 | CLI 提供 `--port` / `--connect-port`（仅测试覆盖，正式端口恒为 34567 / UDP 34568）；集成测试用 `port: 0` 临时端口 |
| C11 | 4GB 内存 + `org.gradle.jvmargs=-Xmx512m` 可能低于 AGP 8/R8 的实际需求 | M7 打包 | 不改约束的缓解已落地：`daemon=false`、`parallel=false`、`workers.max=1`、`android.enableR8.fullMode=false`、**exe 与 apk 严格串行构建**。若仍 OOM，需你同意上调到 `-Xmx768m` |
| C12 | 「应用内存 ≤200 MB」与「8 MiB 帧 + 多会话」 | 运行时 | `FrameReader` 缓冲上限 16 MiB/连接并在每帧后收缩到 8 KiB；`SeqCache` 有界 4096；文件传输 M3 起全程 `RandomAccessFile` 64 KiB 流式。M4 将限制最大并发会话数，保证总内存 <200 MB |

---

## 2. 架构决策

- **三包边界**：`itbridge_core` 是纯 Dart（`dart:io` + `crypto`），不含任何 Flutter 插件；两端 app 负责 UI、权限、路径解析、持久化，core 只接收「路径字符串 / deviceId」。
- **单一端点模型**：`ItbEndpoint` 同时是 TCP 服务端与客户端，因此手机↔手机 / 电脑↔电脑 / 手机↔电脑 三种组合、任一方向都能收发。
- **帧流水线**：`Socket` → `FrameReader(WAIT_HEADER→WAIT_BODY→VERIFY→DISPATCH)` → `Frame` 广播 → `PeerSession` 分发；写出走 `FrameWriter` → `FrameSink`。`MemoryFrameSink` 让单元测试与 M6 中继复用同一套编解码。
- **CRC32 范围**：帧头 `[0,16)` + 4 个 0 字节（CRC 字段置 0）+ 负载，流式计算，不复制整帧。
- **SEQ**：`SeqGenerator` 进程内全局递增（32 位回绕后从 1 继续）；接收端 `SeqCache` 有界去重；`MSG_TEXT` 带 FLAGS bit3，接收端回 ACK。
- **文本拆分**：按 Unicode runes 二分查找最大前缀，保证**实际 JSON 负载** ≤64 KiB 且不切断 UTF-8；`seq`/`ts` 用最大十进制宽度估算，估算为真实长度上界。多行文本原样保留。
- **双拨号去重**：双方同时 `connect` 时，用 `deviceId` 字典序确定性决定保留 outbound / inbound 连接，避免互相关闭震荡。
- **M1 UI 定位**：两端各一个可编译的「冒烟页」，仅用于验证 core 接线；M2/M3 会整体替换为仿微信三栏 / 仿 QQ 五 Tab，会话层不改。

---

## 3. M1 目录树（全部为已落地的完整代码，无 TODO / 伪代码）

```
d:/IT_Bridge/
├── .gitignore
├── analysis_options.yaml
├── README.md                                  ← 本文件
├── assets/
│   └── Android_IT.png                          ← 用户提供的绿底机器人原图
├── tools/
│   ├── gradle.properties                       ← 4GB 内存专项模板
│   └── bootstrap_platforms.ps1                 ← 生成 windows/ 与 android/ 平台壳
├── packages/itbridge_core/
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   ├── lib/
│   │   ├── itbridge_core.dart                  ← 统一导出
│   │   └── src/
│   │       ├── protocol/
│   │       │   ├── constants.dart              ← MAGIC/TYPE/FLAGS/端口/错误码/偏移
│   │       │   ├── crc32.dart                  ← 纯 Dart 流式 CRC32
│   │       │   ├── frame.dart                  ← FrameHeader / Frame
│   │       │   ├── frame_codec.dart            ← 小端编解码 + CRC 校验
│   │       │   ├── frame_reader.dart           ← 四状态机 + 有界缓冲
│   │       │   ├── frame_writer.dart           ← 逐帧写出
│   │       │   ├── messages.dart               ← 各 TYPE 的 JSON 负载 + 64KiB 拆分
│   │       │   └── protocol_exception.dart     ← 带错误码的异常
│   │       ├── transport/
│   │       │   ├── frame_sink.dart             ← Socket / Memory 两种写出目标
│   │       │   ├── itb_socket.dart             ← TCP 连接帧收发
│   │       │   └── tcp_server.dart             ← 监听 + 主动连接
│   │       └── session/
│   │           ├── device_identity.dart        ← 设备身份 / 📱💻 平台
│   │           ├── device_id_store.dart        ← 纯 Dart ID 持久化
│   │           ├── seq_cache.dart              ← SeqGenerator + 有界去重
│   │           ├── peer_session.dart           ← 握手/心跳/ACK/去重/文字收发
│   │           └── itb_endpoint.dart           ← 端点/多会话/设备列表
│   ├── bin/itbridge_cli.dart                   ← 纯 Dart 双端联调命令行
│   └── test/
│       ├── crc32_test.dart
│       ├── frame_codec_test.dart
│       ├── frame_reader_test.dart
│       ├── frame_writer_test.dart
│       ├── seq_cache_test.dart
│       └── endpoint_integration_test.dart
├── apps/itbridge_desktop/
│   ├── pubspec.yaml                            ← 三份 pubspec 全文之一
│   ├── analysis_options.yaml
│   └── lib/main.dart                           ← M1 冒烟 UI
└── apps/itbridge_mobile/
    ├── pubspec.yaml                            ← 三份 pubspec 全文之一
    ├── analysis_options.yaml
    ├── android/gradle.properties               ← 4GB 内存配置（已落地）
    └── lib/main.dart                           ← M1 冒烟 UI
```

> `apps/*/windows/`、`apps/*/android/` 的其余平台壳由 `tools/bootstrap_platforms.ps1` 用 `flutter create` 生成（见 C5）；M7 交付 `AndroidManifest.xml`、`file_paths.xml`、图标替换结果。

---

## 4. 三份 pubspec.yaml

完整内容见：
- `packages/itbridge_core/pubspec.yaml`
- `apps/itbridge_desktop/pubspec.yaml`
- `apps/itbridge_mobile/pubspec.yaml`

依赖版本下界均已在本机 `flutter pub get` / `dart pub get` 解析成功（Dart 3.5.4）。

---

## 5. 构建 / 运行环境清单

| 组件 | 版本 | 备注 |
| --- | --- | --- |
| Flutter | 3.24.5 stable（Dart 3.5.4） | 本机验证用；任何 Flutter 3.x 稳定版 + Dart ≥3.4 均可 |
| JDK | **17**（当前机器是 8，M7 前必须换） | `JAVA_HOME` 指向 JDK 17 |
| Android SDK | platform 35 / build-tools 35 | `compileSdk 35`，Android 13+ 通知权限、`dataSync` 前台服务 |
| Visual Studio | 2022 +「使用 C++ 的桌面开发」 | `flutter build windows --release` 必需 |
| Python | 3.13（已装） | M7 图标转换脚本可选使用；仓库将提供纯 Dart `tools/make_ico.dart` |
| 环境变量 | `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`、`PUB_HOSTED_URL=https://pub.dev` | 国内网络 |
| 图标源文件 | `assets/Android_IT.png` | M7 输出 `app_icon.ico` 与 `mipmap-*/ic_launcher.png` |

### 4GB 内存专项

1. `apps/itbridge_mobile/android/gradle.properties` 与 `tools/gradle.properties` 已写入：
   `org.gradle.jvmargs=-Xmx512m -XX:MaxMetaspaceSize=256m`、`org.gradle.parallel=false`、`org.gradle.daemon=false`，并额外加 `org.gradle.workers.max=1`、`android.enableR8.fullMode=false`。
2. **禁止同时跑 build windows 和 build apk**：M7 的构建脚本会串行执行，且每次构建前关闭浏览器等常驻程序。
3. M1 验证只跑 `dart analyze` / `dart test` / CLI，不触发 Gradle 与 MSBuild，峰值内存 <300 MB。
4. 运行时内存：FrameReader 每连接缓冲上限 16 MiB 且用完即收缩到 8 KiB；文件传输（M3 起）全程 `RandomAccessFile` 64 KiB 分块，绝不整文件入内存。
5. 构建顺序（M7）：先 `flutter build windows --release`，确认产出 `build/windows/x64/runner/Release/IT_Bridge.exe`；**完全退出构建进程后**再 `flutter build apk --release`。

---

## 6. M1 验证步骤与实测结果

```powershell
# 0) 本机验证用 SDK（已就位，可跳过）
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
$env:PUB_HOSTED_URL = 'https://pub.dev'
$env:PUB_CACHE = 'd:\IT_Bridge\.toolchain\pub-cache'
$env:PATH = 'd:\IT_Bridge\.toolchain\sdk\flutter\bin;' + $env:PATH

# 1) core：依赖 + 静态分析 + 全部测试
cd d:\IT_Bridge\packages\itbridge_core
dart pub get
dart analyze                     # 实测：No issues found!
dart test --reporter compact     # 实测：+38 All tests passed!

# 2) 两端 app 静态分析（串行，避免 4GB 内存吃紧）
cd d:\IT_Bridge\apps\itbridge_desktop; flutter pub get; flutter analyze   # No issues found!
cd d:\IT_Bridge\apps\itbridge_mobile;  flutter pub get; flutter analyze   # No issues found!

# 3) 纯 Dart 双端联调（不需编译 exe/apk）
cd d:\IT_Bridge\packages\itbridge_core
# 终端 A
dart run bin/itbridge_cli.dart --name PC-A --connect 127.0.0.1 --connect-port 34568 --port 34567 --config-dir d:\temp\itb-a
# 终端 B
dart run bin/itbridge_cli.dart --name PC-B --port 34568 --config-dir d:\temp\itb-b
# 输入 /peers 查看在线设备，任意输入文字互发；/quit 退出
```

覆盖点：帧头 20 字节小端布局、CRC32 标准向量/流式、CRC 字段置 0 语义、粘包/半包/四状态机、8 MiB 帧上限、全部非法帧错误码（1001/1002/1003/1004）、64 KiB UTF-8 安全拆分、SEQ 去重、HELLO 握手、心跳保活+RTT、双向文字与多行文本、平台图标标注。

**实测结果**：`dart analyze` 0 问题；`dart test` 38/38 通过；`flutter analyze`（desktop / mobile）均 0 问题；CLI `--help` 正常。

---

## 7. 图标替换与 Release 构建（已实际执行）

源图 `assets/Android_IT.png` 为 **1080×900 非正方形**，脚本先居中裁成正方形再缩放，避免拉伸。

- 转换脚本：`tools/make_icons.py`（Python 3.13 + Pillow 12.3.0，本机已装）。
- Windows：输出多尺寸 ICO（16/32/48/64/128/256）→ `apps/itbridge_desktop/windows/runner/resources/app_icon.ico`，已被 `windows/runner/Runner.rc` 的 `IDI_APP_ICON` 引用。
- Android：输出 `mipmap-mdpi 48 / hdpi 72 / xhdpi 96 / xxhdpi 144 / xxxhdpi 192` 的 `ic_launcher.png` 与 `ic_launcher_round.png`。
- 一键串行构建：`powershell -ExecutionPolicy Bypass -File tools/build_release.ps1`。脚本严格按「图标 → Windows exe → Android apk → 产物校验」串行执行，满足 4GB 内存约束。

本机实际安装 / 配置：
- Flutter 3.24.5 + Dart 3.5.4：`.toolchain/sdk/flutter`。
- Microsoft OpenJDK 17.0.21.1：`.toolchain/jdk17`，已通过 `flutter config --jdk-dir` 配置。
- Android SDK：`E:\Android\Sdk`；已补装 Platform 34 / 35、Build Tools 34/35；已通过 `flutter config --android-sdk` 配置。
- Gradle 8.3 发行版下载缓慢，已手动放入 `$USERPROFILE\.gradle\wrapper\dists\gradle-8.3-all\...`。
- Gradle 缓存曾因强制终止出现 `journal-1/file-access.bin` 损坏与 Flutter engine jar ZLIB EOF，清理损坏项后重建成功。
- `gradle.properties` 关闭 Jetifier（所有依赖均为 AndroidX），降低 512m 堆压力；严格保持 `org.gradle.jvmargs=-Xmx512m -XX:MaxMetaspaceSize=256m`、`parallel=false`、`daemon=false`。

实际构建命令（串行，apk 使用 arm64 单架构并关闭图标裁剪）：

```powershell
cd d:\IT_Bridge\apps\itbridge_desktop
flutter build windows --release
cd d:\IT_Bridge\apps\itbridge_mobile
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
```

实测产物：

| 产物 | 路径 | 大小 |
| --- | --- | --- |
| Windows exe | `build/windows/x64/runner/Release/IT_Bridge.exe` | 87,040 B（同目录含 `flutter_windows.dll` 与 `data/`，分发时需整体拷贝） |
| Android apk | `build/app/outputs/flutter-apk/app-release.apk` | 9,014,731 B（8.6 MB，arm64-v8a；使用 debug 签名，仅便于安装验证） |

APK 校验：`aapt dump badging` 显示 `application-label:'IT Bridge'`、`INTERNET` 权限、`minSdk 21`、`targetSdk 34`；ZIP 结构完整，含 `classes.dex`、`lib/arm64-v8a/libapp.so`、`lib/arm64-v8a/libflutter.so`。
Windows exe 为 `IT_Bridge.exe`（CMake `BINARY_NAME` 已改名），运行目录图标来自 `Android_IT.png`。

> 注意：当前 exe/apk 承载的是 **M1 冒烟 UI**（文字消息联调），尚未包含 M2–M7 的文件传输、三栏/五 Tab 界面与实验性广域网功能。

---

## 8. 后续里程碑

| 阶段 | 内容 | 依赖的待确认项 |
| --- | --- | --- |
| M2 | Windows 三栏 UI + 气泡 + 单文件传输 + 电脑↔电脑 | C4、C6（拖拽） |
| M3 | Android 聊天页 + SAF + 手机↔手机 + 文件队列 + 断点续传 | C4、C6（通知/前台服务）、C7（接收目录） |
| M4 | 三端互通 + 设备列表 + 多会话 + 手机↔电脑全流程 | C3（UDP 发现格式） |
| M5 | 设置页 + 四种连接模式 + 免责声明 + ConnectionManager 策略链 | C3 |
| M6 | Dart 单文件中继 + 邀请码配对 + AES-256-GCM | C2（加密依赖） |
| M7 | exe/apk 打包 + 完整 README + 构建说明 + 图标 + 防火墙/权限/测试清单 + 中继 systemd/Nginx WSS 部署 + 上海—陕西双端实测步骤 | C5、C11 |

---

**M1 已完成，请确认是否继续 M2。**
