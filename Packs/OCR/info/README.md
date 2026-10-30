# OCR 文字识别（CurSeen Lua 扩展包）

用官方随包的离线 OCR 工具识别当前贴图（或剪贴板截图）上的文字，结果进 CurSeen 的文本窗，
默认同时复制到剪贴板。

## 官方工具随包

本包安装后会同时得到：

```text
<CurSeen>/assets/lua/scripts/OCR/
├─ 2.ocr_text.lua
├─ pack.json
├─ info/                ← LICENSE / README / HISTORY
└─ ocr_tool/
   ├─ CurSeenOcr.exe
   ├─ ch_PP-OCRv4_det_mobile.onnx
   ├─ ch_PP-OCRv4_rec_mobile.onnx
   ├─ ch_ppocr_mobile_v2.0_cls_mobile.onnx
   └─ ppocr_keys_v1.txt
```

用户**不需要**自己下载或放置引擎。工具由 CurSeen 官方构建、随包分发；源码、构建脚本和
上游版本锁在仓库 [`tools/ocr/`](../../tools/ocr/)（仓库只放源码，编译产物不进仓库）。
脚本用 `requires` 声明这些文件：缺任何一个（例如包没装完整），右键菜单里不会出现「OCR」，
不会给一个点了必然失败的入口。引擎只在本机运行，不联网。

## 安装与用法

在 CurSeen「设置 → 官方资源下载」里刷新并安装；贴图右键 → 脚本 → OCR；没有贴图时用
剪贴板里的截图。脚本页可设「识别后复制文本」与「快捷键」。

## 许可

本包 Lua 代码由 CurSeen 项目独立编写，随 CurSeen 按 GNU AGPL-3.0 分发。
OCR 引擎来自 [RapidOcrOnnx](https://github.com/RapidAI/RapidOcrOnnx)（Apache-2.0），
随包分发时附上游许可证与版本锁；模型文件的 SHA256 见 `tools/ocr/upstream.lock.json`。
