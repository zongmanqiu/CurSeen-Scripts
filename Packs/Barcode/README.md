# 条码识别（CurSeen Lua 扩展包）

解码当前贴图（或剪贴板截图）里的二维码/条形码，结果进 CurSeen 的文本窗：

- 网址：显示 URL；可在脚本页勾选「直接打开网址」（只允许 http/https）。
- 文本 / WiFi / 联系人 / 邮件 / 电话 / 短信 / 位置：显示类型与内容。
- 图片 payload（PNG/JPEG/GIF/BMP/WebP/TIFF/ICO）：还原字节，存临时文件并用系统默认程序打开；
  可在脚本页关掉「直接打开图片」。
- 未知二进制：存为 `.bin` 并显示路径，**不自动打开**。
- SVG / 可执行文件：绝不自动打开。

## 官方工具随包

安装后得到：

```text
<CurSeen>/assets/lua/scripts/
├─ barcode.lua
└─ barcode_tool/
   └─ CurSeenBarcode.exe
```

工具由 CurSeen 官方构建、随包分发；用户不需要自己下载或放置引擎。
源码、构建脚本与上游版本锁在仓库 [`tools/barcode/`](../../tools/barcode/)
（仓库只放源码，编译产物不进仓库）。工具基于
[ZXing-C++](https://github.com/zxing-cpp/zxing-cpp) v3.1.1（Apache-2.0），支持 QR / DataMatrix /
Aztec / PDF417 与常见一维码。

## 安装与用法

在 CurSeen「设置 → 官方资源下载」里刷新并安装；贴图右键 → 脚本 → 条码识别。
没有贴图时用剪贴板里的截图。脚本页可设两个打开开关与「快捷键」。

## 许可

本包 Lua 代码由 CurSeen 项目独立编写，随 CurSeen 按 GNU AGPL-3.0 分发。
ZXing-C++ 的版权与许可见 [`tools/barcode/LICENSE`](../../tools/barcode/LICENSE) 与
`tools/barcode/upstream.lock.json`。
