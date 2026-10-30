# 官方条码 CLI（CurSeenBarcode）

这是 CurSeen 官方二维码/条形码工具的外壳源码与构建脚本。仓库只放源码和构建脚本；
**编译产物不进仓库**，发布时打进 Barcode 包。

## 上游与版本

- 引擎：[zxing-cpp/zxing-cpp](https://github.com/zxing-cpp/zxing-cpp) v3.1.1
- 许可证：Apache-2.0（见 [`LICENSE`](LICENSE)）
- `src/main.cpp` 是 `example/ZXingReader.cpp` 的源码副本。默认输出包含
  `Text`、`Bytes`（十六进制）、`Format`、`Content`，`barcode.lua` 直接解析。

## 构建

1. 解压 ZXing-C++ v3.1.1 源码（`https://github.com/zxing-cpp/zxing-cpp/archive/refs/tags/v3.1.1.tar.gz`）。
2. 准备 `stb_image.h` / `stb_image_write.h`（`nothings/stb`），放在任意目录。
3. 在仓库根运行：

```powershell
powershell -ExecutionPolicy Bypass -File tools/barcode/build.ps1 `
  -ZXingDir <解压后的 zxing-cpp 源码目录> `
  -StbIncludeDir <放有 stb_image*.h 的目录> `
  -OutDir ..\.temp\curseen-tools\barcode
```

脚本会把 `src/main.cpp` 覆盖进 `example/ZXingReader.cpp`、关闭 docs 子目录、
链接静态 ZXing 并编出 `ZXingReader.exe`，复制为 `CurSeenBarcode.exe`。
`OutDir` 的内容发布时装到包内的 `Barcode/barcode_tool/`。
