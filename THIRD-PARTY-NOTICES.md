# 第三方来源与许可

本仓库的 **Lua 代码**由 CurSeen 项目独立编写，随本仓库按 **AGPL-3.0** 分发（全文见
[`LICENSE`](LICENSE)）。下面四个鼠标特效上游项目只被**参考效果与交互**，没有复制其源码、图片、音频、模型或
着色器；名称与链接用于致谢与说明效果来源。OCR / 二维码包另行随包分发上游引擎，
其许可证与版本锁见 `tools/ocr/`、`tools/barcode/`。

| 包 | 上游项目 | 上游许可 |
|---|---|---|
| CursorFX | [devkancheti4-design/cursorfx](https://github.com/devkancheti4-design/cursorfx) | MIT |
| CursorX | [Felix-au/CursorX-Interactive-Cursor-Effects](https://github.com/Felix-au/CursorX-Interactive-Cursor-Effects) | MIT |
| MFCMouseEffect | [sqmw/MFCMouseEffect](https://github.com/sqmw/MFCMouseEffect) | MIT |
| MouseEffects | [ltrudu/MouseEffects](https://github.com/ltrudu/MouseEffects) | MIT |
| OCR 包（官方工具） | [RapidAI/RapidOcrOnnx](https://github.com/RapidAI/RapidOcrOnnx) | Apache-2.0 |
| 二维码包（官方工具） | [zxing-cpp/zxing-cpp](https://github.com/zxing-cpp/zxing-cpp) | Apache-2.0 |

每个包的 `README.md` 与 `LICENSE` 随包分发；OCR / 二维码包的官方工具构建源码与
版本锁在 `tools/ocr/`、`tools/barcode/`，编译产物不进仓库。

## 宿主与运行时

- **CurSeen** 本体：[Gitee](https://gitee.com/qiuzongman/curseen) / [GitHub](https://github.com/zongmanqiu/CurSeen)，
  AGPL-3.0。
- 脚本运行在 CurSeen 内嵌的 **Lua 5.4**（mlua，MIT）上；只有官方 OCR / 二维码包携带
  官方构建的工具，其余脚本包不携带可执行文件。
