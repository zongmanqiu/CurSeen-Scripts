# 条码识别 历史

## 0.2.0（2026-10-30）

- 包结构改为稳定文件夹 `Barcode/`：脚本在 `scripts/` 平铺、官方在 `barcode_tool/`、
  `info/` 放文档、`pack.json` 放配置；一次解压到 `assets/lua/scripts/` 即用。
- 升级按整个包文件夹替换；脚本 id 变为 `scripts/Barcode/barcode`。


## 0.1.1（2026-10-30）

- 说明补全：明确二维码/一维条码、网址打开与图片默认程序打开；显示名统一为条码识别。
- 安装包补文档夹（LICENSE / README / HISTORY），发行日期更新为 2026-10-30。


## 0.1.0（2026-10-30）

- 首个发布：识别 QR / DataMatrix / Aztec / PDF417 / 常见一维码，结果进文本窗。
- 官方 ZXing 工具随包分发，用户无需自备 exe；源码在仓库 `tools/barcode/`。
- 网址可选直接打开（http/https）；图片 payload 可用系统默认程序打开；未知二进制不自动打开。
