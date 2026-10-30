# AI 写脚本（CurSeen Lua 扩展包）

在 CurSeen 里开一个多轮 AI 对话窗，让 AI 帮你编写、修改 CurSeen 的 Lua 脚本。
系统提示词里自带一份 **CurSeen Lua API 速查**（`ai_chat_api.txt`，随包分发），
可以让 AI 直接写拖尾 / 悬浮标 / 点击特效 / 贴图右键脚本，而不靠猜 API。

## 能力

- 对话窗支持多轮上下文；等待回复时标题栏读秒，界面不卡。
- 脚本页可设：**快捷键**、**API 地址**、**模型**、**API Key**。
- 默认接智谱 GLM（`glm-4-flash`），任何兼容 OpenAI `/chat/completions` 的服务都能用。
- 系统提示词每次发送时现读 `./ai_chat_api.txt`：改速查无需重启；速查缺失会明确告知
  「请重新安装」，不会让 AI 臆造 API。
- 回答里的完整 `.lua` 可以保存到 `assets/lua/MouseTrail/`、`HoverDot/`、`ClickFx/`
  或 `scripts/`，保存即热加载。

## 安装

在 CurSeen「设置 → 官方资源下载」里刷新并安装。安装后是稳定的官方包文件夹：

```text
<CurSeen>/assets/lua/scripts/AI/
├─ ai_chat.lua
├─ ai_chat_api.txt
├─ pack.json
└─ info/
   ├─ LICENSE
   ├─ README.md
   └─ HISTORY.md
```

安装后在脚本页打开「AI 写脚本」卡片，填入 API Key 并设置快捷键。

## 用法

1. 按快捷键（或脚本页「运行」）呼出对话窗。
2. 输入框里 `Ctrl+Enter` 发送，`Esc` 关窗；多轮上下文留在窗口内。
3. 直接说「帮我写一个鼠标拖尾的火焰脚本」之类，AI 会按 `ai_chat_api.txt` 的契约
   给出完整脚本和保存位置。
4. API Key 只保存在本机 CurSeen 配置里，脚本不会把它发给除你填写的 API 地址以外的服务。

## 许可

本包代码由 CurSeen 项目独立编写，随 CurSeen 按 GNU AGPL-3.0 分发。
