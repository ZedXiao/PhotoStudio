#!/usr/bin/env python3
"""Run both the automatic and forced-LibRaw paths; retain inspectable evidence."""
import datetime
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
SAMPLES = json.loads((ROOT / "Docs" / "raw-samples.json").read_text())


def validate(probe):
    results = []
    stderr = []
    bundled = []
    for force in (False, True):
        for sample in SAMPLES:
            path = ROOT / ".fixtures" / "raw" / sample["file"]
            if not path.exists():
                raise SystemExit("Missing sample; run script/download_raw_samples.py first: " + sample["file"])
            command = [probe, "--worker"] + (["--libraw"] if force else []) + [str(path)]
            run = subprocess.run(command, capture_output=True, text=True, timeout=180)
            lines = [line for line in run.stdout.splitlines() if line.startswith("{")]
            if not lines:
                raise RuntimeError(f"Probe failed for {path.name}: {run.stderr}")
            record = json.loads(lines[-1])
            assert record["backgroundWorker"] is True
            record.pop("path", None)
            record.update(camera_source=sample["camera"], mode=sample["mode"], source=sample["url"], forcedLibRaw=force)
            if record["status"] == "verified":
                assert record["width"] > 0 and record["height"] > 0 and record["sampleMean"] > 0
                if not force:
                    bundled.append(dict(camera=record.get("camera") or sample["camera"], format=record["format"],
                        mode=sample["mode"], engine=record["engine"], dimensions=f'{record["width"]} × {record["height"]}', source=sample["url"]))
            results.append(record)
            if run.stderr:
                stderr.append(f'{sample["file"]} ({"LibRaw" if force else "automatic"})\n{run.stderr}')
            print(f'{"LibRaw" if force else "Auto":6} {sample["file"]:10} {record["status"]:12} {record.get("engine", "unsupported")} {record.get("width", "")}×{record.get("height", "")}', flush=True)
    now = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=8))).isoformat(timespec="seconds")
    report = dict(validatedAt=now, system=subprocess.check_output(["sw_vers", "-productVersion"], text=True).strip(), results=results)
    (ROOT / "Docs" / "raw-validation.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    (ROOT / "Resources" / "CameraValidation.json").write_text(json.dumps(bundled, ensure_ascii=False, indent=2) + "\n")
    (ROOT / ".fixtures" / "decoder-stderr.log").write_text("\n".join(stderr))
    lines = ["# RAW 样片验证", "", f'验收时间：{now}。运行系统：macOS {report["system"]}，Apple Silicon。', "",
        "样片来自 raw.pixls.us，均为 CC0；下载清单保存来源 URL 和 SHA-256。主图检查完整解码后的尺寸与非空像素，并验证缩略图能否生成。自动路径优先 Apple RAW，失败后回退到内置 LibRaw；另行强制 LibRaw 验证回退实现。", "",
        "| 相机 | 格式／拍摄模式 | 自动解码 | 尺寸 | 强制 LibRaw | 缩略图 |", "| --- | --- | --- | --- | --- | --- |"]
    count = len(SAMPLES)
    for index, sample in enumerate(SAMPLES):
        automatic, fallback = results[index], results[index + count]
        mode = sample["mode"].replace("|", "/")
        engine = automatic.get("engine", "暂不支持")
        dimensions = f'{automatic["width"]} × {automatic["height"]}' if automatic["status"] == "verified" else "—"
        fallback_status = "通过" if fallback["status"] == "verified" else "暂不支持"
        thumb = "通过" if automatic.get("thumbnail") else "未生成"
        lines.append(f'| {sample["camera"]} | {Path(sample["file"]).suffix[1:].upper()} · {mode} | {engine} | {dimensions} | {fallback_status} | {thumb} |')
    lines += ["", "## 适用范围", "", "以上结果只对应清单中的具体原始文件和当前系统。机型列表不代表所有位深、压缩模式、固件和裁切模式均已验证。系统解码能力会随 macOS 更新变化。", "",
        "应用与 LibRaw 源码的最低系统及编译部署目标为 macOS 26。当前环境在 macOS 27.2 验证，macOS 26 与 Intel 尚未进行真机运行验收。", "",
        "本构建启用 LibRaw 内置解码器及 zlib；未集成 Adobe DNG SDK、GoPro SDK、RawSpeed、外部 JPEG 库和 LCMS。需要这些可选组件的格式变体可能仅能由系统处理，或显示暂不支持。", "",
        "完整逐文件结果、耗时、原始方向和错误原因见 [raw-validation.json](raw-validation.json)。", "",
        "## 竖拍方向回归", "", "另以 CC0 Sony ARW 样片创建仅修改 TIFF 方向标签的两份副本（EXIF 6 与 8），原始样片保持不变。运行 validate_portraits.py 可分别验证 Apple RAW、强制 LibRaw 和缩略图，结果见 [portrait-validation.json](portrait-validation.json)。", "",
        "源样片目录的位深描述偶有容器位深与传感器位深混用；界面保留可确认的压缩模式，原始目录描述存于下载清单的 sourceMode 字段。", ""]
    (ROOT / "Docs" / "RAW-Validation.md").write_text("\n".join(lines))
    print(f'Bundled verified samples: {len(bundled)}/{len(SAMPLES)}', flush=True)


if __name__ == "__main__":
    validate(sys.argv[1])
