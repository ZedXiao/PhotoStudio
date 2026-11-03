# LibRaw 0.22.3

Source: https://www.libraw.org/data/LibRaw-0.22.3-macOS.zip

Upstream archive SHA-256: `1edd33c66be1cfdc74e0a471c4143d25f0172234a46a44dce5511a396a35af55`

The upstream source and build files are unmodified. Prebuilt command-line tools, prebuilt archives, and autotools caches were omitted. SwiftPM compiles the full processing implementation, excluding the upstream `_ph.cpp` placeholder implementations. The app and LibRaw both compile with a macOS 26.0 deployment target. LibRaw stays source-built so the dependency configuration and background-worker regression checks remain reproducible.

The project enables built-in RAW decoders and zlib. Optional Adobe DNG SDK, GoPro SDK, RawSpeed, JPEG library and LCMS integrations are not compiled in; individual format variants requiring these optional integrations may need Apple system decoding or may report unsupported. Declared camera names alone are not treated as verified support.

LibRaw is used under its CDDL 1.0 option. See the upstream `COPYRIGHT`, `LICENSE.CDDL` and `LICENSE.LGPL`. Corresponding source is also included in the application resources as `LibRaw-0.22.3-source.zip`.
