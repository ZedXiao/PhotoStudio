# 1.0.1：RAW 后台线程栈溢出修复

用户提供的报告显示 `PhotoStudio.FullImage` 队列在 `ps_raw_orientation` 中触发 `Thread stack size exceeded`。LibRaw 实例大于 macOS 工作线程常见的 512 KiB 栈；此前在 C++ 桥接函数内局部创建实例，在主线程探针中正常，在应用的后台线程中会退出。

完整解码、缩略图提取和方向读取三个入口均改为 `std::unique_ptr` 管理的堆分配实例。生命周期与异常处理保持在调用内部，返回时自动释放。

新增 512 KiB 独立线程回归测试，覆盖三个 RAW 桥接入口。样片探针增加 `--worker` 模式，所有 RAW 样片与竖拍复验均在与应用相同的 `OperationQueue` 后台环境执行，结果记录 `backgroundWorker: true`，避免主线程较大的栈掩盖此类问题。
