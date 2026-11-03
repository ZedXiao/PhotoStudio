# 文档索引 / Documentation index

[简体中文首页](../README.md) · [English home](../README.en.md)

当前版本为 **1.2.6（构建 10）**。下表中的中英文指南描述当前实现；历史验收记录保留当时版本的行为和验证范围，部分行为已被后续版本替代。

The current version is **1.2.6 (build 10)**. The guides below describe the current implementation in both languages. Historical records describe their original versions and verification scope; later versions supersede some behavior.

## 指南 / Guides

| 内容 / Topic | 简体中文 | English |
| --- | --- | --- |
| 功能、安装、使用与快捷键 / Features, setup, usage, shortcuts | [README](../README.md) | [README](../README.en.md) |
| 构建、架构、调试、测试、贡献 / Build, architecture, debugging, tests, contributions | [开发指南](Development.zh-CN.md) | [Development guide](Development.en.md) |
| 版本变化 / Version history | [更新日志](CHANGELOG.md) | [Changelog](CHANGELOG.en.md) |
| RAW 兼容性与样片 / RAW compatibility and samples | [RAW 验证记录](RAW-Validation.md) | [RAW validation](RAW-Validation.en.md) |
| 第三方组件与许可 / Third-party components and licenses | [双语声明 / Bilingual notices](Third-Party-Notices.md) | [Dependency provenance](../Vendor/README.md) |

## 可检查的数据 / Inspectable evidence

| 文件 / File | 内容 / Contents |
| --- | --- |
| [raw-samples.json](raw-samples.json) | 18 份 CC0 样片来源、拍摄模式及 SHA-256 / Sources, capture modes, and SHA-256 values for 18 CC0 samples |
| [raw-validation.json](raw-validation.json) | 逐文件自动与强制 LibRaw 解码结果 / Per-file automatic and forced-LibRaw results |
| [portrait-validation.json](portrait-validation.json) | EXIF 6、8 方向副本的双引擎与缩略图回归 / Both decoders and thumbnail checks for EXIF 6/8 derivatives |
| [CameraValidation.json](../Resources/CameraValidation.json) | 应用兼容窗口使用的验证摘要 / Validation summary used by the application's compatibility window |

## 历史记录 / Historical records

以下原始记录使用中文，英文版本摘要见 [English changelog](CHANGELOG.en.md)。这些既有记录并不代表每次文档更新都重新执行了完整验收。

The original records below are in Chinese; the English changelog summarizes their changes. Retaining a record does not imply that every documentation update reruns its full verification.

| 版本 / Version | 原始记录 / Original record |
| --- | --- |
| 1.2.6 | [箭头凸起轮廓 / Arrow tab contour](PhotoStudio-1.2.6.md) |
| 1.2.5 | [玻璃面板阴影 / Glass panel shadows](PhotoStudio-1.2.5.md) |
| 1.2.4 | [固定尺寸总览收起 / Fixed-size overview dismissal](PhotoStudio-1.2.4.md) |
| 1.2.3 | [覆盖式缩略图面板 / Overlay thumbnail panel](PhotoStudio-1.2.3.md) |
| 1.2.2 | [缩略图面板过渡 / Thumbnail panel transitions](PhotoStudio-1.2.2.md) |
| 1.2.1 | [目录行与窗口内删除确认 / Folder rows and in-window deletion confirmation](PhotoStudio-1.2.1.md) |
| 1.2.0 | [目录树、总览、手势与删除偏好 / Folder tree, overview, gestures, deletion preferences](PhotoStudio-1.2.0.md) |
| 1.1.0 | [macOS 26 与 Liquid Glass / macOS 26 and Liquid Glass](Liquid-Glass-1.1.0.md) |
| 1.0.1 | [RAW 后台线程栈修复 / RAW worker-stack fix](Crash-Fix-1.0.1.md) |
| 1.0.1 UI | [原生界面验收 / Original native UI verification](UI-Validation.md) |
