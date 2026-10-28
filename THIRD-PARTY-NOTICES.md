# 第三方来源与许可

本仓库的 **Lua 代码**由 CurSeen 项目独立编写，随本仓库按 **AGPL-3.0** 分发（全文见
[`LICENSE`](LICENSE)）。下面四个上游项目只被**参考效果与交互**，没有复制其源码、图片、
音频、模型或着色器；名称与链接用于致谢与说明效果来源。

| 包 | 上游项目 | 上游许可 |
|---|---|---|
| CursorFX | [devkancheti4-design/cursorfx](https://github.com/devkancheti4-design/cursorfx) | MIT |
| CursorX | [Felix-au/CursorX-Interactive-Cursor-Effects](https://github.com/Felix-au/CursorX-Interactive-Cursor-Effects) | MIT |
| MFCMouseEffect | [sqmw/MFCMouseEffect](https://github.com/sqmw/MFCMouseEffect) | MIT |
| MouseEffects | [ltrudu/MouseEffects](https://github.com/ltrudu/MouseEffects) | MIT |

每个包的 `README.md` 与 `LICENSE` 随包分发（宿主安装时会存进 `<exe>/lua_packs/<id>/`
留档），其中有该包单独的致谢与来源说明。

## 宿主与运行时

- **CurSeen** 本体：[Gitee](https://gitee.com/qiuzongman/curseen) / [GitHub](https://github.com/zongmanqiu/CurSeen)，
  AGPL-3.0。
- 脚本运行在 CurSeen 内嵌的 **Lua 5.4**（mlua，MIT）上；脚本包本身不携带任何可执行文件。
