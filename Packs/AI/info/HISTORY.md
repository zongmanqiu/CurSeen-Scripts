# AI 写脚本 历史

## 0.2.0（2026-10-31）

- **速查（`ai_chat_api.txt`）全面对齐 CurSeen 2.1.0 / LUA_API 3**：补齐当时缺失的
  18 个 `ext` 接口（proc / 文件读写与图片 / set_image / data_dir / 剪贴板 / 对话框 /
  unzip / download / chat_window 等）、ExtImage 的 crop/rotate/flip 与 JPEG 保存、
  `image` 参数的真实语义、`KeySound/` 键音目录、v2 包规则与 `category`/`requires`。
- 修正旧速查里的过时说法：贴图右键菜单叫「脚本」（不是「图片操作」）、
  `schema` 支持 `image`（仅路径框占位）、`play_sound` 仅复合脚本可用。
- **补“悬停/静止 N 秒”可用的 HoverDot 示例**，并写清硬规则：沙盒没有 `os`/`io`、
  `init()` 无参数、`ctx` 只能在 `draw`、静止检测要 `draw` 返回毫秒续帧、时间用 `wall_ms`；
  速查末尾新增生成前自检清单，专门防“写法看起来对、运行完全没效果”。
- 安装入口更新为「脚本」页第一张卡「官方资源下载」；脚本代码未改。
- **对话历史持久化**（宿主 2.1.1 起）：会话保存到 `<程序目录>/data/ai_chat/history.json`，
  关窗 / 重启后自动恢复，只有「清除」才清空；速查与脚本说明同步。

## 0.1.0（2026-10-30）

- 首次作为官方资源包发布：脚本与 `ai_chat_api.txt` 速查从宿主内置迁到
  `Packs/AI/`，安装到 `assets/lua/scripts/AI/`。
- 保留多轮对话窗、API 地址 / 模型 / API Key / 快捷键参数，以及速查随包读取。
