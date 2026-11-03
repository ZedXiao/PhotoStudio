# 第三方声明 / Third-party notices

[项目首页](../README.md) · [English home](../README.en.md)

## LibRaw 0.22.3

PhotoStudio 包含 LibRaw 0.22.3，Copyright © 2008–2025 LibRaw LLC。项目选择上游提供的 **CDDL 1.0** 选项；上游同时附带 LGPL 2.1 许可文本。完整版权及所含组件的声明保留在原始文件中。

PhotoStudio includes LibRaw 0.22.3, Copyright © 2008–2025 LibRaw LLC. The project selects the upstream **CDDL 1.0** option. Upstream also supplies an LGPL 2.1 license text. Original files retain the full copyright and component notices.

| 内容 / Item | 路径或来源 / Location or source |
| --- | --- |
| 上游归档 / Upstream archive | [LibRaw-0.22.3-macOS.zip](https://www.libraw.org/data/LibRaw-0.22.3-macOS.zip) |
| 上游归档 SHA-256 / Upstream archive SHA-256 | `1edd33c66be1cfdc74e0a471c4143d25f0172234a46a44dce5511a396a35af55` |
| 源码与构建说明 / Source and build notes | [Vendor/README.md](../Vendor/README.md) · [Vendor/LibRaw-0.22.3](../Vendor/LibRaw-0.22.3) |
| 上游版权 / Upstream copyright | [COPYRIGHT](../Vendor/LibRaw-0.22.3/COPYRIGHT) |
| CDDL 1.0 | [LICENSE.CDDL](../Vendor/LibRaw-0.22.3/LICENSE.CDDL) |
| LGPL 2.1 | [LICENSE.LGPL](../Vendor/LibRaw-0.22.3/LICENSE.LGPL) |
| 应用内声明 / Bundled notice | [Resources/Licenses/NOTICE.txt](../Resources/Licenses/NOTICE.txt) |
| 应用内对应源码 / Bundled corresponding source | [LibRaw-0.22.3-source.zip](../Resources/Licenses/LibRaw-0.22.3-source.zip) |

上游源码及构建文件未修改；仓库省略了上游预编译工具、预编译归档及 autotools 缓存。SwiftPM 从源码静态编译 LibRaw，启用内置解码器和 zlib；未启用 Adobe DNG SDK、GoPro SDK、RawSpeed、外部 JPEG 库和 LCMS 集成。上表校验值对应下载的上游归档，不是项目重新整理后的源码压缩包。

Upstream source and build files are unmodified; prebuilt tools, prebuilt archives, and autotools caches were omitted. SwiftPM statically compiles LibRaw from source with built-in decoders and zlib. Adobe DNG SDK, GoPro SDK, RawSpeed, external JPEG, and LCMS integrations are not enabled. The checksum above identifies the downloaded upstream archive, not the project's repackaged source ZIP.

应用资源保留完整版权、两份上游许可文本、声明和对应源码压缩包。

Application resources retain the complete copyright notice, both upstream license texts, a notice, and the corresponding source ZIP.

## RAW 验证样片 / RAW validation samples

固定测试清单仅选择 [raw.pixls.us](https://raw.pixls.us/) 的 CC0 文件。[清单](raw-samples.json) 逐项保存来源 URL、机型、模式与 SHA-256。下载后的原图和衍生测试副本保存在被 Git 忽略的 `.fixtures/` 中，不随仓库或应用打包；仓库仅保存清单和验证结果。

The fixed manifest selects CC0 files from raw.pixls.us. The [manifest](raw-samples.json) records each source URL, camera, mode, and SHA-256. Downloaded originals and derived fixtures stay in the Git-ignored `.fixtures/` directory and are not packaged with the repository or application. Only the manifest and validation results are retained in the repository.

## PhotoStudio 自有代码 / PhotoStudio's own code

本仓库目前尚未为 PhotoStudio 自有代码指定项目级许可证。上述第三方许可适用于对应组件，不代表已为整个项目指定同一许可。

No project-wide license has been specified for PhotoStudio's own code. The third-party licenses above apply to their respective components and do not designate a license for the entire project.
