# PhotoStudio

**简体中文** | [English](README.en.md)

原生 macOS 相机照片浏览器，支持文件夹目录树、完整 RAW 解码和 Liquid Glass 界面。基于 SwiftUI、AppKit、ImageIO、Core Image 和内置 LibRaw 0.22.3，直接浏览原位置的照片，无需导入图库。

当前版本：**1.2.7（构建 11）** · 最低系统：**macOS 26.0** · 已验收架构：**Apple Silicon**。应用当前主要使用中文界面；本仓库提供中英文文档。

## 功能

- **目录浏览**：添加多个文件夹，按需展开子目录，每层仅显示自身照片；按目录记忆 RAW 开关、展开状态，并恢复上次浏览位置。
- **照片预览**：适应窗口、100% 实际像素、捏合缩放与拖动平移；横竖照片在主预览和缩略图中均居中显示。
- **快速选片**：底部胶片条和可展开的大缩略图总览；预览箭头、方向键和触控板单次滑动切图，过滤惯性连跳。
- **RAW 支持**：优先使用 Apple RAW，失败后回退到内置 LibRaw；显示相机和曝光参数，区分样片验证与解码器声明支持。
- **废纸篓操作**：窗口内确认后移到系统废纸篓，可选择同时处理同目录、同主文件名的 RAW，并记住该选择。
- **原生界面**：Liquid Glass、系统窗口与侧栏；缩略图总览展开和收起时保留主图缩放及平移位置，响应“减少动态效果”设置。

## 环境要求

| 项目 | 要求 |
| --- | --- |
| 运行系统 | macOS 26.0 或更新版本 |
| 开发工具 | 完整 Xcode 26 或更新版本，包含 macOS 26 或更新 SDK |
| 构建工具 | Xcode 自带 Swift、Clang、SwiftPM 和系统签名工具 |
| 可选验证 | Python 3.9+，用于下载和复验公开 RAW 样片 |
| 已验证环境 | Apple Silicon，macOS 27.2；macOS 26 真机与 Intel 尚未验收 |

## 下载与安装

从 [GitHub Release v1.2.7](https://github.com/ZedXiao/PhotoStudio/releases/tag/v1.2.7) 下载 DMG 或 ZIP，适用于 **macOS 26.0+、Apple Silicon（arm64）**。DMG 打开后将 PhotoStudio 拖到“应用程序”；ZIP 解压后复制应用即可，运行时无需 Xcode。发布页同时提供 SHA-256 校验文件。

**签名与公证：此版本采用临时签名（ad hoc），未使用 Apple Developer ID 签名，未做苹果公证（Apple notarization）。**

## 从源码构建

```sh
git clone https://github.com/ZedXiao/PhotoStudio.git
cd PhotoStudio
./script/build_and_run.sh
```

构建生成 `dist/PhotoStudio.app` 并启动，可在访达双击或复制到“应用程序”。脚本优先使用 `/Applications/Xcode.app`；Xcode 安装在其他位置时，可设置 `DEVELOPER_DIR`，详见[开发指南](Docs/Development.zh-CN.md)。

LibRaw 源码已随项目提供，常规构建和照片浏览无需下载第三方依赖或测试样片。缓存保存在 `.build/`，应用输出和下载的测试照片均不纳入 Git。当前脚本生成本机临时签名的开发应用，未执行 Developer ID 签名或公证。

```sh
./script/build_and_run.sh --build-only  # 只生成 .app
./script/build_and_run.sh --verify      # 构建、启动并检查进程
./script/package.sh                    # Release 构建，生成 DMG、ZIP 和 SHA-256
./script/test.sh                       # 核心逻辑测试，无需下载 RAW 样片
```

自行打包的安装包保存在 `dist/`，采用与上述 Release 相同的临时签名方式。

## 使用方式

1. 选择“添加文件夹…”或“打开照片…”，也可将文件／文件夹拖入窗口。
2. 在侧栏展开目录树，点击要浏览的目录；父目录不会汇总子目录照片。RAW 默认隐藏，直接打开 RAW 会自动开启所在目录的 RAW 显示。
3. 点击缩略图选择照片。双击主图在适应窗口与 100% 之间切换；放大后可拖动或用触控板滚动平移。
4. 点击底部胶片条上沿的向上箭头展开总览，单击选择、双击打开；点击向下箭头或按 Esc 收起。大面板下滑时逐步露出固定的胶片条。
5. 使用“移到废纸篓…”删除当前照片。配套 RAW 首次默认不勾选，之后记住上次选择，包括取消和重启后；隐藏的 RAW 也能配对。直接删除 RAW 只处理当前文件，失败逐文件报告。

侧栏叉号和“从列表中移除”仅移除保存的目录记录，磁盘文件保留。目录移动或磁盘离线时，可以重试或重新选择位置。

## 快捷键与手势

| 操作 | 快捷键／手势 |
| --- | --- |
| 打开照片 | `⌘O` |
| 添加文件夹 | `⇧⌘O` |
| 上一张／下一张 | `←` / `→`，或预览浮动箭头 |
| 触控板切图 | 适应窗口时横向滑动，一次手势最多一张 |
| 放大／缩小 | `⌘=` / `⌘-`，或触控板捏合 |
| 适应窗口／100% | `⌘0` / `⌘1`，或双击主图切换 |
| 刷新目录 | `⌘R` |
| 切换 RAW 显示 | `⇧⌘R` |
| 显示／隐藏胶片条 | `⌥⌘T` |
| 移到废纸篓 | `⌘⌫` |
| 收起总览／取消删除确认 | `Esc` |

## RAW 兼容性与性能

主图始终完整解码 RAW，优先 Apple Core Image，失败后使用静态编译的 LibRaw 0.22.3；缩略图可使用内嵌预览。实际支持取决于相机型号、压缩方式与运行系统，识别扩展名并不保证可解码。

现有验证记录包含 **18 份 CC0 原始样片**：自动路径全部通过，强制 LibRaw 通过 16 份；两份 Nikon Z 8 高效率 NEF 样片依赖系统解码。这些结果对应记录中的具体文件及系统，详见 [RAW 验证记录](Docs/RAW-Validation.md)。帮助菜单的“RAW 相机兼容”分别显示验证样片、声明支持机型和本次失败记录。

完整解码队列串行执行，优先当前照片，最多预取下一张，并取消过期请求。完整图像缓存预算为物理内存的 1/8 与 512 MiB 中较小值；缩略图独立限流和缓存。

## 开发与文档

| 内容 | 中文 | English |
| --- | --- | --- |
| 构建、架构、调试、测试及贡献 | [开发指南](Docs/Development.zh-CN.md) | [Development guide](Docs/Development.en.md) |
| 版本变化 | [更新日志](Docs/CHANGELOG.md) | [Changelog](Docs/CHANGELOG.en.md) |
| 相机样片与适用范围 | [RAW 验证](Docs/RAW-Validation.md) | [RAW validation](Docs/RAW-Validation.en.md) |
| 全部文档与历史验收记录 | [文档索引](Docs/README.md) | [Documentation index](Docs/README.md) |
| 依赖、源码与许可 | [第三方声明 / Third-party notices](Docs/Third-Party-Notices.md) | [Dependency provenance](Vendor/README.md) |

项目使用 SwiftPM，提供 `PhotoStudio` 应用和 `PhotoStudioProbe` 验收工具。当前核心测试共 **18 项**，涵盖扫描、配对、删除、选择、EXIF 方向、偏好、触控板事件及 512 KiB 后台线程栈回归。RAW 下载与复验命令见开发指南。

LibRaw 按其 CDDL 1.0 选项使用，上游版权、许可证及对应源码归档保留在仓库和应用资源内。PhotoStudio 自有代码尚未指定项目级许可证；第三方许可范围见[第三方声明](Docs/Third-Party-Notices.md)。
