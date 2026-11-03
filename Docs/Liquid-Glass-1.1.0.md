# 1.1.0：macOS 26 与 Liquid Glass

最低系统要求统一为 macOS 26.0：SwiftPM 平台声明、开发脚本的部署目标、应用 Info.plist 和最终 Mach-O 均为 26.0。开发脚本要求 macOS 26 或更新 SDK。

界面使用系统提供的 Liquid Glass：

- 保留原生 NavigationSplitView、侧栏、窗口与统一工具栏，移除旧的平面底色和栏背景。
- 工具栏使用 ToolbarSpacer 标记动作组，由系统绘制玻璃控件。
- 文件信息和 RAW／子目录开关位于浮动玻璃面板；缩略图与拍摄信息共用下方玻璃面板。
- 相邻玻璃面板归入同一 GlassEffectContainer；玻璃材质未施加到照片像素内容上。
- 欢迎页、添加文件夹和确认框按钮采用系统 glass／glassProminent 样式，材质随系统外观和辅助功能设置调整。

当前 Apple Silicon Mac、macOS 27.2 上完成构建、启动和实际界面检查：JPEG 与富士 RAW 预览、RAW 开关、100%／适应窗口、删除框配套 RAW 默认不勾选及取消、连续 JPEG／RAW 切换均正常。12 项核心测试通过，含 512 KiB 后台线程栈回归。18 份原始 RAW 样片自动预览通过，后台完整复验和竖拍结果分别见 raw-validation.json 与 portrait-validation.json。

当前自动化的拖动未实际改变窗口尺寸，窄窗口布局未完成交互验收。macOS 26、Intel 和系统深色外观尚未进行单独真机／交互验收。
