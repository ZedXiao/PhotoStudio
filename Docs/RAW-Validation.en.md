# RAW sample validation

[简体中文](RAW-Validation.md) | **English** · [Project home](../README.en.md)

Recorded validation: **2026-11-02T17:34:56+08:00**, macOS **27.2**, Apple Silicon. This is an English rendering of the existing results, not a new decoding run.

All samples are CC0 files from raw.pixls.us. The [download manifest](raw-samples.json) records source URLs and SHA-256 checksums. Validation checks full-image dimensions and nonempty pixel data, plus thumbnail generation. Automatic decoding tries Apple RAW first and bundled LibRaw second; forced LibRaw separately exercises the fallback implementation. All records use background workers.

| Camera | Format / capture mode | Automatic decoder | Dimensions | Forced LibRaw | Thumbnail |
| --- | --- | --- | --- | --- | --- |
| Canon EOS 5D Mark IV | CR2 · RAW · not Dual Pixel RAW | Apple RAW | 6720 × 4480 | Passed | Passed |
| Canon EOS R6 | CR3 · C-RAW · 1.6× crop | Apple RAW | 3408 × 2272 | Passed | Passed |
| Canon EOS R6 | CR3 · RAW | Apple RAW | 5472 × 3648 | Passed | Passed |
| Nikon D750 | NEF · 12-bit lossy compressed | Apple RAW | 6016 × 4016 | Passed | Passed |
| Nikon D750 | NEF · 14-bit lossless compressed | Apple RAW | 6016 × 4016 | Passed | Passed |
| Nikon Z 8 | NEF · high efficiency (sample labeled low) | Apple RAW | 8256 × 5504 | Unsupported | Passed |
| Nikon Z 8 | NEF · 14-bit lossless compressed | Apple RAW | 8256 × 5504 | Passed | Passed |
| Nikon Z 8 | NEF · high efficiency (sample labeled high) | Apple RAW | 8256 × 5504 | Unsupported | Passed |
| Sony ILCE-7M3 | ARW · 14-bit compressed | Apple RAW | 6000 × 4000 | Passed | Passed |
| Sony ILCE-7M3 | ARW · 14-bit uncompressed | Apple RAW | 6000 × 4000 | Passed | Passed |
| Fujifilm X-T3 | RAF · 14-bit compressed · X-Trans | Apple RAW | 6240 × 4160 | Passed | Passed |
| Fujifilm X-T3 | RAF · 14-bit uncompressed · X-Trans | Apple RAW | 6240 × 4160 | Passed | Passed |
| Panasonic DC-S5 | RW2 · standard resolution | Apple RAW | 6000 × 4000 | Passed | Passed |
| Panasonic DC-S5 | RW2 · 96-megapixel high-resolution composite | Apple RAW | 12000 × 8000 | Passed | Passed |
| Olympus E-M10 Mark II | ORF · standard RAW | Apple RAW | 4608 × 3456 | Passed | Passed |
| Pentax K-3 | PEF · 14-bit PEF | Apple RAW | 6016 × 4000 | Passed | Passed |
| Leica M10 | DNG · uncompressed DNG | Apple RAW | 5952 × 3968 | Passed | Passed |
| Hasselblad X1D | 3FR · standard 3FR | Apple RAW | 8272 × 6200 | Passed | Passed |

Automatic decoding passed **18/18** samples; forced LibRaw passed **16/18**. The two Nikon Z 8 high-efficiency samples rely on system decoding in this configuration.

## Scope

Results apply only to these specific original files and the recorded operating system. A camera's presence does not verify every bit depth, compression mode, firmware version, or crop mode. System RAW support can change with macOS updates.

The application and LibRaw source have a minimum deployment target of macOS 26. Validation was performed on macOS 27.2; macOS 26 hardware and Intel execution have not been verified.

This build enables LibRaw's built-in decoders and zlib. It does not integrate Adobe DNG SDK, GoPro SDK, RawSpeed, an external JPEG library, or LCMS. Variants requiring optional integrations may depend on system decoding or report unsupported.

See [raw-validation.json](raw-validation.json) for per-file results, timings, source orientation, and errors. Some upstream sample descriptions mix container bit depth and sensor bit depth; original descriptions are retained in the manifest's `sourceMode` field.

## Portrait orientation regression

Two derivatives of the CC0 Sony ARW sample modify only the TIFF orientation tag to EXIF 6 and 8. Originals remain unchanged. The portrait script verifies Apple RAW, forced LibRaw, and thumbnail orientation using background workers. See [portrait-validation.json](portrait-validation.json) and the [development guide](Development.en.md) for results and repeatable commands.
