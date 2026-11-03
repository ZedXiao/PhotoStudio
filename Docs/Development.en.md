# Development guide

[简体中文](Development.zh-CN.md) | **English** · [Project home](../README.en.md)

## Toolchain and first build

Use macOS 26.0+ and full Xcode 26+. Command Line Tools alone do not supply the SDK required by this project. Optional RAW sample scripts require Python 3.9+; normal builds and core tests need no photo downloads.

```sh
git clone https://github.com/ZedXiao/PhotoStudio.git
cd PhotoStudio
./script/build_and_run.sh --build-only
./script/test.sh
```

`script/toolchain.sh` prefers `/Applications/Xcode.app/Contents/Developer`, sets the deployment target to macOS 26.0, and checks the SDK major version. For another Xcode installation, set this before running project scripts:

```sh
export DEVELOPER_DIR="/path/to/Xcode.app/Contents/Developer"
./script/build_and_run.sh --build-only
```

`.build/` contains SwiftPM, module, and configuration caches; `dist/` contains application output. The Run action in `.codex/environments/environment.toml` uses the same build script.

## Common commands

| Command | Behavior |
| --- | --- |
| `./script/build_and_run.sh` | Compile, assemble the bundle, ad hoc sign, and launch |
| `./script/build_and_run.sh --build-only` | Compile and create `dist/PhotoStudio.app` |
| `./script/build_and_run.sh --build-only --configuration release` | Create an optimized Release application |
| `./script/package.sh` | Release build, drag-install DMG, ZIP, and SHA-256 checksum file |
| `./script/build_and_run.sh --verify` | Build, launch, and check that the process exists |
| `./script/build_and_run.sh --debug` | Build and run under LLDB |
| `./script/build_and_run.sh --logs` | Build, launch, and stream system logs for the process |
| `./script/build_and_run.sh --telemetry` | Build, launch, and filter logs by subsystem `app.photostudio.mac` |
| `./script/test.sh` | Run all core XCTest cases |
| `./script/test.sh --filter DecoderTests` | Run decoding tests only |

The build script stops existing PhotoStudio processes before recreating the bundle. Debug is the default; `--configuration release` selects an optimized build. Packaging reuses that entry point and verifies the application signature and disk image. The DMG contains the app and an Applications shortcut, the ZIP contains the app directly, and the checksum file covers both packages. Scripts target the current machine architecture and do not create a universal binary, perform Developer ID signing or notarization, or upload a release.

The icon artwork source is `Resources/AppIconArtwork.png`. `script/generate_icon.swift` applies consistent rounded corners, transparent margins, and a shadow, then writes `Resources/AppIcon.png` and `Resources/AppIcon.icns` with 16–1024 pixel representations. Editing the artwork or generator automatically regenerates the icon on the next build. The [icon design record](AppIcon-Design.md) preserves the final generation prompt.

## Project layout

| Path | Responsibility |
| --- | --- |
| `Package.swift` | SwiftPM products, targets, resources, and minimum macOS version |
| `App/` | Application entry, windows, menus, and external file opening |
| `Views/` | Folder sidebar, photo canvas, thumbnails, deletion confirmation, and compatibility UI |
| `Stores/` | Folder and preference persistence, window browsing state, tree loading, and decoding records |
| `Services/ImagePipeline.swift` | Full-image and thumbnail queues, cancellation, and memory caches |
| `Models/`, `Support/` | Folder models and application resource access |
| `Sources/PhotoStudioCore/` | Scanning, filtering, pairing, Trash operations, decoding, orientation, and metadata |
| `Sources/CLibRawBridge/` | C++ decoding bridge with cancellation and explicit memory ownership |
| `Sources/PhotoStudioProbe/` | Command-line validation tool, separate from application execution |
| `Vendor/LibRaw-0.22.3/` | Upstream LibRaw compiled from included source |
| `Resources/` | Info.plist, icon, help, validation summary, and third-party licenses/source |
| `Tests/PhotoStudioCoreTests/` | Core behavior and worker-thread regression tests |
| `script/`, `Docs/` | Build/validation tools and inspectable documentation evidence |

SwiftPM exports two executable products: `PhotoStudio` and `PhotoStudioProbe`. The application needs the script-assembled `.app` for its full resources and Info.plist; compiling an executable alone does not produce an application bundle.

## Data flow and constraints

`LibraryStore` persists folders, bookmarks, and per-directory preferences. `FolderTreeStore` loads directory levels on demand. `BrowserStore` manages the current directory, selection, zoom requests, overview, and deletion confirmation. Scanning indexes RAW files even when hidden so companion matching still works.

`ImagePipeline` sends images to `StandardPhotoDecoder`. Regular images use ImageIO with EXIF orientation normalization; RAW uses Core Image first, then LibRaw. Full decoding is serial, with selected photos prioritized over prefetching. Selection revisions prevent stale results from replacing the current photo. The full-image cache budget is `min(physical memory / 8, 512 MiB)`; thumbnails have a 64 MiB cache and at most two concurrent tasks.

Main images and thumbnails may use different decoding strategies: main previews fully decode the image, while thumbnails may use embedded previews. LibRaw instances must be heap allocated; see the [1.0.1 worker-stack fix](Crash-Fix-1.0.1.md) in Chinese.

Photos remain at their original paths. `DeletePlan` matches companion RAW files only when the directory and filename stem match exactly. Directly deleting RAW does not include other files. `TrashService` uses the system Trash API and records successes and failures per file. Verify deletion changes with generated fixtures or separate copies.

## Core tests

```sh
./script/test.sh
```

The current 18 tests cover independent directory levels and natural sorting, hidden files and symlinks, RAW pairing, partial deletion failures, selection recovery, cancellation, corrupt files, EXIF orientations 1–8, metadata, image dimensions, directory preferences, RAW deletion preferences, trackpad lifecycles, and a 512 KiB worker-stack regression. Tests create temporary files and require no public RAW samples.

## Optional RAW and portrait validation

The fixed [raw-samples.json](raw-samples.json) manifest contains source URLs and SHA-256 values for 18 CC0 samples. The initial download is approximately 780 MiB and stays in the Git-ignored `.fixtures/raw/` directory:

```sh
python3 script/download_raw_samples.py
./script/validate_raw.sh
```

Validation runs automatic and forced-LibRaw decoding for every file with `--worker` on a background thread. It rewrites `Docs/raw-validation.json`, `Docs/RAW-Validation.md`, and the application's `Resources/CameraValidation.json`, and saves decoder diagnostics to `.fixtures/decoder-stderr.log`. Update the English validation report when results change.

Use SwiftPM's reported product path for the standalone probe and portrait regression, rather than assuming a `.build` directory layout:

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

The probe emits one JSON record per input with the decoder, dimensions, metadata, duration, thumbnail result, and background-worker status. It exits nonzero on decoding failure. The portrait script creates EXIF orientation 6 and 8 derivatives from the public Sony sample, checks Apple RAW, LibRaw, and thumbnails, and updates `Docs/portrait-validation.json`.

`script/create_ui_fixtures.swift` generates JPEG fixtures and RAW copies for UI verification; it requires downloaded samples. The application supports `--isolated` for separate QA preferences. After building, launch it with:

```sh
open -n dist/PhotoStudio.app --args --isolated
```

## Troubleshooting

| Symptom | Check |
| --- | --- |
| SDK version rejected | Use full Xcode 26+ and verify that `DEVELOPER_DIR` points to the intended installation |
| Only an executable was built | Use `build_and_run.sh` to assemble the `.app` and resources rather than only `swift build` |
| A RAW file fails | Record the camera, compression mode, macOS version, and probe error; compare system and LibRaw paths |
| Folder moved or volume offline | Retry or locate the folder in the application, then refresh |
| Validation reports a missing sample | Run the downloader first and ensure SHA-256 checks pass |

## Contributions and version maintenance

Before submitting changes, run `./script/test.sh` and `./script/build_and_run.sh --build-only`. Verify UI changes in the actual application, including interactions, keyboard focus, and Reduce Motion. Decoder changes need relevant RAW and portrait checks. A process-existence check confirms launch, not full UI verification.

Issue reports should include the application version, macOS version, chip architecture, reproduction steps, and expected/actual behavior. RAW reports should specify camera and compression mode and provide a public sample link when shareable. Remove private paths and photo information from logs before posting them.

Keep Chinese and English READMEs, development guides, and changelogs synchronized. `Resources/Info.plist` defines the application version and build number. When raising the minimum OS, check `Package.swift`, `script/toolchain.sh`, and Info.plist together. Preserve upstream LibRaw copyright, license texts, and corresponding source; see [third-party notices](Third-Party-Notices.md).
