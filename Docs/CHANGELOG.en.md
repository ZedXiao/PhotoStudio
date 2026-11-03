# Changelog

[简体中文](CHANGELOG.md) | **English** · [Project home](../README.en.md)

This log summarizes existing version notes. Linked original records preserve implementation and verification details in Chinese. The README and development guide describe current behavior.

## 1.2.6 (build 10) — 2026-11-03

- Give the thumbnail panel's arrow tab a gentle 36 pt flat top, with an overall width of 104 pt and height of 10 pt.
- Join each shoulder smoothly to the panel edge using three cubic curves, preserving shadow space and fixed-size slide dismissal.

[Original record](PhotoStudio-1.2.6.md)

## 1.2.5 (build 9) — 2026-11-03

- Reserve 24 pt for native glass shadows, fixing rectangular clipping around rounded corners and residual shadows after dismissal.
- Enlarge the arrow hit area while retaining the fixed preview, filmstrip, and 220 ms slide.

[Original record](PhotoStudio-1.2.5.md)

## 1.2.4 (build 8) — 2026-11-03

- Keep large thumbnails at a fixed size and slide the entire panel down with a 220 ms ease-out transition to reveal the filmstrip.
- Allow reversal during animation; keep preview geometry and zoom/pan out of the layout animation and switch directly with Reduce Motion.

[Original record](PhotoStudio-1.2.4.md)

## 1.2.3 (build 7) — 2026-11-03

- Make the overview a bottom overlay, preserving the main preview's fit scale and 100% pan position.
- Add an integrated glass arrow tab on the panel's top edge for opening and closing the overview.

[Original record](PhotoStudio-1.2.3.md)

## 1.2.2 (build 6) — 2026-11-03

- Share one glass panel between overview and filmstrip with a unified expansion/dismissal path, reducing preview reinsertion jumps.
- Unify Esc, double-click, and button dismissal; disable main-image zoom controls while the overview is open.

[Original record](PhotoStudio-1.2.2.md)

## 1.2.1 (build 5)

- Use stable identifiers and fixed-height native sidebar rows, with loading and failure states shown inside the corresponding row.
- Move deletion confirmation into a single glass panel in the current window, managing focus, Esc, Return, and disabled background controls.

[Original record](PhotoStudio-1.2.1.md)

## 1.2.0 (build 4) — 2026-11-02

- Introduce an on-demand folder tree, independent RAW/expansion preferences per directory, and restoration of the last visited subdirectory.
- Add a large-thumbnail overview, floating preview arrows, and trackpad navigation limited to one photo per gesture.
- Fix portrait and landscape centering, persist companion-RAW deletion preferences, and move bookmark creation off the main thread.
- Expand core coverage to 18 tests for directories, preferences, gestures, and existing decoding regressions.

[Original record and interaction verification](PhotoStudio-1.2.0.md)

## 1.1.0

- Align the minimum system and all deployment declarations to macOS 26.0 and adopt native Liquid Glass.
- Retain system windows, sidebar, and toolbar, without applying glass material to photo pixels.

[Original record](Liquid-Glass-1.1.0.md)

## 1.0.1

- Heap-allocate LibRaw instances in full decoding, thumbnail, and orientation entry points to fix background-worker stack overflow.
- Add a 512 KiB worker-stack regression and `PhotoStudioProbe --worker` so sample validation exercises background execution.

[Fix details](Crash-Fix-1.0.1.md) · [Early UI verification](UI-Validation.md)
