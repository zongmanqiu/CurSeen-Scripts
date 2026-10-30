# 官方 OCR CLI（CurSeenOcr）

这是 CurSeen 官方 OCR 工具的外壳源码与构建脚本。仓库里只放源码、构建脚本和锁文件；
**编译产物与模型不进仓库**，发布时由 `tools/build_packs.py` 打进 OCR 包。

## 上游与版本

- 引擎：[RapidAI/RapidOcrOnnx](https://github.com/RapidAI/RapidOcrOnnx)
- 固定提交：见 [`upstream.lock.json`](upstream.lock.json)
- 许可证：Apache-2.0（见 [`LICENSE`](LICENSE)）
- `src/main.cpp` 是官方 CLI 的源码副本（提交 `675e73f…`），输出契约由
  `2.ocr_text.lua` 的 `parse_lines` 负责解析。

## 构建

1. 从 RapidOcrOnnx Release 下载整合工程（含源码、onnxruntime/OpenCV 静态库）：
   `Project_RapidOcrOnnx-1.2.2.7z`，解压到任意目录。
2. 准备模型（PP-OCRv4，四个文件：det / rec / cls / 字典；SHA256 见 `upstream.lock.json`）。
3. 在仓库根运行：

```powershell
powershell -ExecutionPolicy Bypass -File tools/ocr/build.ps1 `
  -ProjectDir <解压后的 Project_RapidOcrOnnx 目录> `
  -ModelsDir <放有 5 个模型文件的目录> `
  -OutDir ..\.temp\curseen-tools\ocr
```

脚本会把 `src/main.cpp` 覆盖进工程、用 VS2022（v143）编 Release BIN，并把
`CurSeenOcr.exe` 与模型复制到 `OutDir`。构建脚本同时传入
`OpenCV_ARCH=x64 / OpenCV_RUNTIME=vc16`：工程里的 OpenCV 静态库是 VS2019 的，
MSVC v142/v143 ABI 兼容，但 `OpenCVConfig.cmake` 不认 VS2022 的 194x 版本号。

发布时 `OutDir` 的内容会装到 `assets/lua/scripts/ocr_tool/`；`2.ocr_text.lua`
的 `requires` 与 `TOOL` 都指向这里。用户只装包，不需要自己准备工具。
