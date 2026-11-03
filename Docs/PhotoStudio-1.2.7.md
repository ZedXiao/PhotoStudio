# PhotoStudio 1.2.7（构建 11）

2026-11-03。

- 使用浅色底、蓝绿色六叶光圈和暖黄色中心替换原先的深色应用图标。
- 保留生成的图案源文件；原生导出脚本统一应用圆角、透明留白和轻阴影，输出 PNG 预览与多尺寸 ICNS。构建会检测图案和脚本的更新。
- 构建入口增加 `--configuration debug|release`，默认开发流程保持 Debug；`script/package.sh` 复用该入口进行 Release 构建、签名校验、DMG／ZIP 打包和 SHA-256 生成。
- DMG 包含 `PhotoStudio.app` 和指向 `/Applications` 的拖拽安装入口。

## 验证

在 Apple Silicon、macOS 27.2 和 Xcode 的 macOS 27.2 SDK 上完成以下检查：

- `./script/test.sh`：18 项核心测试全部通过，无失败。
- `./script/package.sh`：Release 编译、应用组装与临时签名完成。
- `iconutil` 成功展开最终 ICNS，检查 16、32 和 1024 像素表示；PNG 预览和 ICNS 均为 1024 × 1024，具有透明通道。
- 原应用、ZIP 解压应用和 DMG 内应用均通过 `codesign --verify --deep --strict`；两种安装包中的图标与源 ICNS 一致。
- DMG 校验和验证通过；只读挂载后确认应用和 `/Applications` 快捷入口存在，检查后已卸载。
- ZIP 解压后的应用独立启动成功，恢复目录并显示照片；“关于”窗口确认新图标与版本 `1.2.7 (11)`。
- 对最终 DMG、ZIP 执行 SHA-256 复核均通过。

## 交付

- `dist/PhotoStudio.app`
- `dist/PhotoStudio-1.2.7-macOS26-arm64.dmg`
- `dist/PhotoStudio-1.2.7-macOS26-arm64.zip`
- `dist/PhotoStudio-1.2.7-macOS26-arm64.sha256`

最低系统为 macOS 26.0，当前交付 Apple Silicon 应用。本次在上述本机环境验证，未新增 macOS 26 真机或 Intel 验收。安装包使用临时签名，未进行 Developer ID 签名或苹果公证。

图标源文件与最终提示词见[图标设计记录](AppIcon-Design.md)。
