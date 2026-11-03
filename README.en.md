# PhotoStudio

[简体中文](README.md) | **English**

A native macOS camera photo browser with a folder tree, full RAW decoding, and Liquid Glass UI. Built with SwiftUI, AppKit, ImageIO, Core Image, and bundled LibRaw 0.22.3, PhotoStudio browses photos in their original folders without importing them into a library.

Current version: **1.2.6 (build 10)** · Minimum OS: **macOS 26.0** · Validated architecture: **Apple Silicon**. The application currently uses a primarily Chinese interface; this repository provides Chinese and English documentation.

## Features

- **Folder browsing:** add multiple folders, expand subfolders on demand, and browse each directory independently. RAW visibility, expansion, and the last browsing location persist across launches.
- **Photo preview:** fit to window, actual pixels at 100%, pinch to zoom, and drag to pan. Portrait and landscape photos stay centered in previews and thumbnails.
- **Quick selection:** a bottom filmstrip and expandable thumbnail overview, with preview arrows, keyboard navigation, and one photo per trackpad swipe with momentum filtering.
- **RAW support:** Apple RAW decoding with bundled LibRaw fallback, camera and exposure metadata, and a compatibility view that distinguishes tested files from declared support.
- **Move to Trash:** an in-window confirmation offers to include RAW files with the same filename stem in the same directory and remembers the choice.
- **Native interface:** Liquid Glass, system windows, and a native sidebar. Opening and closing the overview preserves preview zoom and pan and respects Reduce Motion.

## Requirements

| Component | Requirement |
| --- | --- |
| Operating system | macOS 26.0 or later |
| Developer tools | Full Xcode 26 or later, including the macOS 26 SDK or newer |
| Build tools | Swift, Clang, SwiftPM, and system signing tools supplied with Xcode |
| Optional validation | Python 3.9+ for downloading and validating public RAW samples |
| Validated environment | Apple Silicon running macOS 27.2; macOS 26 hardware and Intel have not been validated |

## Quick start

```sh
git clone https://github.com/ZedXiao/PhotoStudio.git
cd PhotoStudio
./script/build_and_run.sh
```

The script builds and launches `dist/PhotoStudio.app`. You can open the bundle in Finder or copy it to Applications. Scripts prefer `/Applications/Xcode.app`; set `DEVELOPER_DIR` for another Xcode location as described in the [development guide](Docs/Development.en.md).

LibRaw source is included. Normal builds and photo browsing require no third-party dependency or test-photo downloads. Caches stay in `.build/`; generated applications and downloaded fixtures are excluded from Git. The script creates an ad hoc signed development application; it does not perform Developer ID signing or notarization.

```sh
./script/build_and_run.sh --build-only  # Build the .app only
./script/build_and_run.sh --verify      # Build, launch, and check the process
./script/test.sh                       # Core tests; no RAW sample downloads required
```

## Using PhotoStudio

1. Choose “添加文件夹…” (Add Folder) or “打开照片…” (Open Photo), or drag files or folders into the window.
2. Expand the sidebar tree and select a directory. A parent directory does not combine its descendants' photos. RAW files are hidden by default; opening a RAW file directly enables RAW visibility for its directory.
3. Select a thumbnail. Double-click the main image to switch between fit to window and 100%. When zoomed in, drag or scroll with the trackpad to pan.
4. Click the up arrow on the filmstrip's top edge to open the overview. Single-click to select, double-click to open, or use the down arrow or Esc to close it. The large panel slides down to reveal the stationary filmstrip.
5. Choose “移到废纸篓…” (Move to Trash). Including companion RAW files is initially off, then remembers your last choice even after cancellation or relaunch. Hidden RAW files can be matched. Deleting a RAW file directly affects only that file; failures are reported per file.

The sidebar's remove button and “从列表中移除” (Remove from List) remove the saved folder entry while keeping files on disk. A moved folder or offline volume can be retried or located again.

## Keyboard shortcuts and gestures

| Action | Shortcut / gesture |
| --- | --- |
| Open photo | `⌘O` |
| Add folder | `⇧⌘O` |
| Previous / next photo | `←` / `→`, or floating preview arrows |
| Trackpad navigation | Swipe horizontally while fitted; at most one photo per gesture |
| Zoom in / out | `⌘=` / `⌘-`, or pinch on the trackpad |
| Fit / actual pixels | `⌘0` / `⌘1`, or double-click the main image to toggle |
| Refresh folder | `⌘R` |
| Toggle RAW visibility | `⇧⌘R` |
| Toggle filmstrip | `⌥⌘T` |
| Move to Trash | `⌘⌫` |
| Close overview / cancel deletion | `Esc` |

## RAW compatibility and performance

Main previews always decode the full RAW image, trying Apple Core Image first and statically compiled LibRaw 0.22.3 next. Thumbnails may use embedded previews. Actual support depends on the camera, compression mode, and operating system; recognizing a file extension does not guarantee decoding.

The existing validation record covers **18 CC0 original samples**: all passed automatic decoding, and 16 passed forced LibRaw decoding. Two Nikon Z 8 high-efficiency NEF samples require system decoding. Results apply to the specific files and system in the [RAW validation report](Docs/RAW-Validation.en.md). The Help menu's compatibility view separates tested samples, declared camera support, and failures in the current session.

Full decoding runs serially, prioritizes the selected photo, prefetches at most the next photo, and cancels stale requests. The full-image cache budget is the smaller of one eighth of physical memory and 512 MiB. Thumbnails use a separate queue and cache.

## Development and documentation

| Topic | 中文 | English |
| --- | --- | --- |
| Build, architecture, debugging, tests, and contributions | [开发指南](Docs/Development.zh-CN.md) | [Development guide](Docs/Development.en.md) |
| Version history | [更新日志](Docs/CHANGELOG.md) | [Changelog](Docs/CHANGELOG.en.md) |
| Camera samples and scope | [RAW 验证](Docs/RAW-Validation.md) | [RAW validation](Docs/RAW-Validation.en.md) |
| All documentation and historical verification | [文档索引](Docs/README.md) | [Documentation index](Docs/README.md) |
| Dependencies, source, and licenses | [第三方声明 / Third-party notices](Docs/Third-Party-Notices.md) | [Dependency provenance](Vendor/README.md) |

The SwiftPM package provides the `PhotoStudio` application and the `PhotoStudioProbe` validation tool. Its **18 core tests** cover scanning, pairing, deletion, selection, EXIF orientation, preferences, trackpad events, and a 512 KiB worker-stack regression. RAW download and validation commands are in the development guide.

LibRaw is used under its CDDL 1.0 option. Upstream copyright, license texts, and corresponding source are retained in the repository and application resources. No project-wide license has been specified for PhotoStudio's own code; see [third-party notices](Docs/Third-Party-Notices.md) for dependency licensing scope.
