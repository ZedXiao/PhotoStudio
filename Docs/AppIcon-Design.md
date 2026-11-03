# PhotoStudio 图标设计 / Icon design

2026-11-03 · PhotoStudio 1.2.7（构建 11）。

采用浅色底、蓝绿色六叶光圈及暖黄色中心。图案使用内置 `image_gen` 生成，未使用 CLI 或单独的 API 调用。透明底草稿因边缘杂点未采用；最终使用不透明的完整画布作为图案源文件，由项目原生图标脚本统一生成圆角和透明留白。

- 图案源文件 / Artwork: `Resources/AppIconArtwork.png`
- 最终预览 / Final preview: `Resources/AppIcon.png`
- 应用图标 / App icon: `Resources/AppIcon.icns`
- 导出脚本 / Export script: `script/generate_icon.swift`

## 最终提示词 / Final prompt

```text
Use case: logo-brand.
Asset type: full-bleed square artwork source for a production macOS app icon for PhotoStudio, a lightweight local photo browser.
Create one fresh, light, cheerful, beautifully polished graphic: a large six-blade photographic aperture made of broad curved ribbons in luminous sky blue and turquoise, with one small sunlight-yellow hexagonal opening at the center.
Composition: one centered aperture on a uniform very pale icy ivory background. Aperture diameter about 72 percent of image width. Front-facing, square 1024 x 1024 composition, no perspective.
Style: elegant simple native desktop icon, smooth crisp geometry, restrained soft depth and very subtle internal shading. Airy and friendly, strong silhouette at 32 pixels.
Critical production constraints: the pale ivory background MUST cover the ENTIRE square image edge to edge. This is an opaque full-bleed source texture; do NOT draw rounded corners, a tile outline, external padding, a mockup frame or any transparent area. The app's native icon renderer will apply the final rounded-square mask later. No background objects, no dark navy, no camera body, no thin outlines, no rainbow flower, no text, letters, numbers, watermarks, border, outer drop shadow or surrounding scene.
```
