# 开发指南

**简体中文** | [English](Development.en.md) · [返回项目首页](../README.md)

## 工具链与首次构建

需要 macOS 26.0+ 和完整 Xcode 26+，仅安装 Command Line Tools 不足以提供本项目需要的 SDK。可选 RAW 样片脚本需要 Python 3.9+；常规构建和核心测试不需要下载照片。

```sh
git clone https://github.com/ZedXiao/PhotoStudio.git
cd PhotoStudio
./script/build_and_run.sh --build-only
./script/test.sh
```

`script/toolchain.sh` 会优先使用 `/Applications/Xcode.app/Contents/Developer`，设置 macOS 26.0 部署目标，并检查 SDK 主版本。若 Xcode 安装在其他位置，在执行项目脚本前设置：

```sh
export DEVELOPER_DIR="/path/to/Xcode.app/Contents/Developer"
./script/build_and_run.sh --build-only
```

`.build/` 保存 SwiftPM、模块与配置缓存；`dist/` 保存应用输出。`.codex/environments/environment.toml` 中的 Run 操作调用相同的构建脚本。

## 常用命令

| 命令 | 行为 |
| --- | --- |
| `./script/build_and_run.sh` | 编译、组装应用、临时签名并启动 |
| `./script/build_and_run.sh --build-only` | 编译并生成 `dist/PhotoStudio.app` |
| `./script/build_and_run.sh --build-only --configuration release` | 生成经过优化的 Release 应用 |
| `./script/package.sh` | Release 构建，生成拖拽安装 DMG、ZIP 和 SHA-256 校验文件 |
| `./script/build_and_run.sh --verify` | 构建、启动并检查进程存在 |
| `./script/build_and_run.sh --debug` | 构建后通过 LLDB 运行 |
| `./script/build_and_run.sh --logs` | 构建、启动并查看该进程的系统日志 |
| `./script/build_and_run.sh --telemetry` | 构建、启动并按 `app.photostudio.mac` 子系统筛选日志 |
| `./script/test.sh` | 运行全部核心 XCTest |
| `./script/test.sh --filter DecoderTests` | 仅运行解码相关测试 |

构建脚本会先结束现有 PhotoStudio 进程，再重建应用包，默认使用 Debug；`--configuration release` 切换到优化构建。打包脚本复用同一个构建入口，并校验应用签名和磁盘映像。DMG 内包含应用和指向“应用程序”的快捷入口，ZIP 内直接包含应用，校验文件覆盖两种安装包。脚本使用当前机器架构，不生成通用二进制，也不执行 Developer ID 签名、公证或上传发布。

图标图案源文件为 `Resources/AppIconArtwork.png`。`script/generate_icon.swift` 统一应用圆角、透明留白和阴影，输出 `Resources/AppIcon.png` 及包含 16–1024 像素表示的 `Resources/AppIcon.icns`。修改图案或脚本后，下一次构建会自动重新生成；[图标设计记录](AppIcon-Design.md) 保存最终生成提示词。

## 工程结构

| 路径 | 职责 |
| --- | --- |
| `Package.swift` | SwiftPM 产品、目标、资源及 macOS 最低版本 |
| `App/` | 应用入口、窗口、菜单、外部文件打开路由 |
| `Views/` | 目录侧栏、照片画布、缩略图、删除确认及兼容界面 |
| `Stores/` | 目录及偏好持久化、窗口浏览状态、目录树和实际解码记录 |
| `Services/ImagePipeline.swift` | 完整图像／缩略图队列、取消和内存缓存 |
| `Models/`、`Support/` | 目录模型及应用资源访问 |
| `Sources/PhotoStudioCore/` | 扫描、筛选、配对、废纸篓、解码、方向和元数据 |
| `Sources/CLibRawBridge/` | 支持取消的 C++ 解码桥接及内存所有权边界 |
| `Sources/PhotoStudioProbe/` | 命令行解码验证工具，独立于应用运行 |
| `Vendor/LibRaw-0.22.3/` | 随源码编译的上游 LibRaw |
| `Resources/` | Info.plist、图标、帮助、样片验证摘要及第三方许可／源码 |
| `Tests/PhotoStudioCoreTests/` | 核心行为和后台线程回归 |
| `script/`、`Docs/` | 构建／验证工具及可检查的文档证据 |

SwiftPM 导出两个可执行产品：`PhotoStudio` 与 `PhotoStudioProbe`。应用需要脚本组装的 `.app` 才具备完整应用资源和 Info.plist；单独编译可执行文件不等同于生成应用包。

## 数据流与约束

`LibraryStore` 保存已添加目录、书签及目录偏好；`FolderTreeStore` 按需加载目录层级；`BrowserStore` 管理当前目录、选择、缩放请求、总览和删除确认。扫描会索引当前目录内的 RAW，即使它们暂时隐藏，以支持正确配对。

`ImagePipeline` 将图像交给 `StandardPhotoDecoder`。普通图片通过 ImageIO 解码并应用 EXIF 方向，RAW 优先使用 Core Image，再尝试 LibRaw。完整解码队列一次处理一个任务，当前选择优先于预取；窗口状态用选择版本阻止过期结果覆盖当前照片。完整图像缓存预算为 `min(物理内存 / 8, 512 MiB)`，缩略图缓存为 64 MiB、最多两个并行任务。

主图和缩略图允许使用不同解码策略：主图完整解码，缩略图可读取内嵌预览。LibRaw 实例必须在堆上创建；参见 [1.0.1 后台线程栈修复](Crash-Fix-1.0.1.md)。

照片保留在原路径。`DeletePlan` 仅匹配同目录、主文件名完全相同的 RAW；直接删除 RAW 时不附带其他文件。`TrashService` 调用系统废纸篓 API，并逐文件记录成功与失败。修改删除流程后，使用生成样片或独立副本复验。

## 核心测试

```sh
./script/test.sh
```

当前共有 18 项测试，覆盖：目录层级分离和自然排序、隐藏文件与符号链接、RAW 配对、部分删除失败、选择恢复、取消、损坏文件、EXIF 1–8 方向、元数据、图像尺寸、目录偏好、RAW 删除选择、触控板生命周期和 512 KiB 工作线程栈回归。测试会创建临时文件，无需公开 RAW 样片。

## 可选 RAW 与竖拍复验

固定清单 [raw-samples.json](raw-samples.json) 包含 18 份 CC0 样片的来源和 SHA-256。首次下载约 780 MiB，保存在不纳入 Git 的 `.fixtures/raw/`：

```sh
python3 script/download_raw_samples.py
./script/validate_raw.sh
```

验证工具对每个文件分别运行自动路径和强制 LibRaw 路径，使用 `--worker` 在后台执行。它会改写 `Docs/raw-validation.json`、`Docs/RAW-Validation.md` 和应用内的 `Resources/CameraValidation.json`，并将解码器诊断保存到 `.fixtures/decoder-stderr.log`。英文验证说明需要在结果变化时同步更新。

使用 SwiftPM 实际返回的产品路径运行单独探针和竖拍回归，避免假设 `.build` 内部目录结构：

```sh
bash <<'SH'
set -euo pipefail
source script/toolchain.sh
swift build "${PHOTOSTUDIO_SWIFT_FLAGS[@]}" --product PhotoStudioProbe
photostudio_bin="$(swift build "${PHOTOSTUDIO_SWIFT_FLAGS[@]}" --show-bin-path)"
"$photostudio_bin/PhotoStudioProbe" --worker --libraw .fixtures/raw/2414.arw
python3 script/validate_portraits.py "$photostudio_bin/PhotoStudioProbe"
SH
```

探针每个输入文件输出一行 JSON，记录解码器、尺寸、元数据、耗时、缩略图和后台执行状态，解码失败时以非零状态退出。竖拍脚本从公开 Sony 样片生成 EXIF 6、8 的方向副本，检查 Apple RAW、LibRaw 和缩略图，更新 `Docs/portrait-validation.json`。

可通过 `script/create_ui_fixtures.swift` 生成 UI 验收 JPEG 及 RAW 副本；它依赖已下载的样片。应用支持 `--isolated` 使用独立 QA 偏好，例如构建后运行：

```sh
open -n dist/PhotoStudio.app --args --isolated
```

## 排查问题

| 现象 | 检查方式 |
| --- | --- |
| 提示 SDK 版本不足 | 确认使用完整 Xcode 26+，并检查 `DEVELOPER_DIR` 是否指向预期安装 |
| 仅编译出可执行文件 | 使用 `build_and_run.sh` 组装 `.app` 与资源，而非只调用 `swift build` |
| 某份 RAW 无法打开 | 记录具体机型、压缩模式、macOS 和探针错误；检查系统／LibRaw 两条路径 |
| 文件夹离线或移动 | 在应用内重试、重新选择目录，然后刷新 |
| 复验报缺少样片 | 先运行下载脚本，确保 SHA-256 校验通过 |

## 贡献与版本维护

提交改动前运行 `./script/test.sh` 与 `./script/build_and_run.sh --build-only`。UI 改动还需在实际应用检查交互、键盘焦点和减少动态效果；解码改动需复验相关 RAW 及竖拍方向。进程检查通过仅代表成功启动，不代表完整 UI 验收。

问题报告请包含应用版本、macOS、芯片架构、复现步骤、预期／实际行为；RAW 问题附机型及压缩模式，并在可分享时给出公开样片链接。提交日志前移除私人路径和照片信息。

同步维护中英文 README、开发指南和更新日志。应用版本与构建号以 `Resources/Info.plist` 为准；若提高最低系统版本，同步检查 `Package.swift`、`script/toolchain.sh` 和 Info.plist。保留上游 LibRaw 的版权、许可及对应源码，依赖详情见[第三方声明](Third-Party-Notices.md)。
