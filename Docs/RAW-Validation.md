# RAW 样片验证

验收时间：2026-11-02T17:34:56+08:00。运行系统：macOS 27.2，Apple Silicon。

样片来自 raw.pixls.us，均为 CC0；下载清单保存来源 URL 和 SHA-256。主图检查完整解码后的尺寸与非空像素，并验证缩略图能否生成。自动路径优先 Apple RAW，失败后回退到内置 LibRaw；另行强制 LibRaw 验证回退实现。

| 相机 | 格式／拍摄模式 | 自动解码 | 尺寸 | 强制 LibRaw | 缩略图 |
| --- | --- | --- | --- | --- | --- |
| Canon EOS 5D Mark IV | CR2 · RAW · 非双像素 RAW | Apple RAW | 6720 × 4480 | 通过 | 通过 |
| Canon EOS R6 | CR3 · C-RAW · 1.6× 裁切 | Apple RAW | 3408 × 2272 | 通过 | 通过 |
| Canon EOS R6 | CR3 · RAW | Apple RAW | 5472 × 3648 | 通过 | 通过 |
| Nikon D750 | NEF · 12 位有损压缩 | Apple RAW | 6016 × 4016 | 通过 | 通过 |
| Nikon D750 | NEF · 14 位无损压缩 | Apple RAW | 6016 × 4016 | 通过 | 通过 |
| Nikon Z 8 | NEF · 高效率压缩（样片标注 low） | Apple RAW | 8256 × 5504 | 暂不支持 | 通过 |
| Nikon Z 8 | NEF · 14 位无损压缩 | Apple RAW | 8256 × 5504 | 通过 | 通过 |
| Nikon Z 8 | NEF · 高效率压缩（样片标注 high） | Apple RAW | 8256 × 5504 | 暂不支持 | 通过 |
| Sony ILCE-7M3 | ARW · 14 位压缩 | Apple RAW | 6000 × 4000 | 通过 | 通过 |
| Sony ILCE-7M3 | ARW · 14 位未压缩 | Apple RAW | 6000 × 4000 | 通过 | 通过 |
| Fujifilm X-T3 | RAF · 14 位压缩 · X-Trans | Apple RAW | 6240 × 4160 | 通过 | 通过 |
| Fujifilm X-T3 | RAF · 14 位未压缩 · X-Trans | Apple RAW | 6240 × 4160 | 通过 | 通过 |
| Panasonic DC-S5 | RW2 · 标准尺寸 | Apple RAW | 6000 × 4000 | 通过 | 通过 |
| Panasonic DC-S5 | RW2 · 9600 万像素高分辨率合成 | Apple RAW | 12000 × 8000 | 通过 | 通过 |
| Olympus E-M10 Mark II | ORF · 标准 RAW | Apple RAW | 4608 × 3456 | 通过 | 通过 |
| Pentax K-3 | PEF · 14 位 PEF | Apple RAW | 6016 × 4000 | 通过 | 通过 |
| Leica M10 | DNG · 未压缩 DNG | Apple RAW | 5952 × 3968 | 通过 | 通过 |
| Hasselblad X1D | 3FR · 标准 3FR | Apple RAW | 8272 × 6200 | 通过 | 通过 |

## 适用范围

以上结果只对应清单中的具体原始文件和当前系统。机型列表不代表所有位深、压缩模式、固件和裁切模式均已验证。系统解码能力会随 macOS 更新变化。

应用与 LibRaw 源码的最低系统及编译部署目标为 macOS 26。当前环境在 macOS 27.2 验证，macOS 26 与 Intel 尚未进行真机运行验收。

本构建启用 LibRaw 内置解码器及 zlib；未集成 Adobe DNG SDK、GoPro SDK、RawSpeed、外部 JPEG 库和 LCMS。需要这些可选组件的格式变体可能仅能由系统处理，或显示暂不支持。

完整逐文件结果、耗时、原始方向和错误原因见 [raw-validation.json](raw-validation.json)。

## 竖拍方向回归

另以 CC0 Sony ARW 样片创建仅修改 TIFF 方向标签的两份副本（EXIF 6 与 8），原始样片保持不变。运行 validate_portraits.py 可分别验证 Apple RAW、强制 LibRaw 和缩略图，结果见 [portrait-validation.json](portrait-validation.json)。

源样片目录的位深描述偶有容器位深与传感器位深混用；界面保留可确认的压缩模式，原始目录描述存于下载清单的 sourceMode 字段。
