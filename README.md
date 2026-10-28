# CurSeen 脚本仓库

> **仓库入口**：[**Gitee**](https://gitee.com/qiuzongman/CurSeen-Scripts) | [**GitHub**](https://github.com/zongmanqiu/CurSeen-Scripts)

CurSeen 的**脚本包**来源：每个包是一份 zip，装进 CurSeen 的 `assets/lua/`，由宿主
「设置 → 官方资源下载」列出、下载、更新、卸载。当前四个包都是鼠标特效（源码在
[`MouseEffect/`](MouseEffect/)，一个子目录 = 一个包）。

★ 本仓库**只放源码**：打包出来的 zip 不提交、不进仓库（生成到仓库外 `../.temp/curseen-scripts-dist/`）。
版本从 **0.1.0** 起；出厂包在宿主里认领为 `v0.0.0`，所以首个在线版本仍会显示为「升级」。

## 发布包

| 包 | 版本 | 脚本数 | 体积 | Gitee | GitHub |
|---|---:|---:|---:|---|---|
| CursorFX | 0.1.0 | 42 | 95.7 KB | [下载](https://gitee.com/qiuzongman/CurSeen-Scripts/releases/download/CursorFX_0.1.0/CursorFX_0.1.0.zip) | [下载](https://github.com/zongmanqiu/CurSeen-Scripts/releases/download/CursorFX_0.1.0/CursorFX_0.1.0.zip) |
| CursorX | 0.1.0 | 24 | 50.4 KB | [下载](https://gitee.com/qiuzongman/CurSeen-Scripts/releases/download/CursorX_0.1.0/CursorX_0.1.0.zip) | [下载](https://github.com/zongmanqiu/CurSeen-Scripts/releases/download/CursorX_0.1.0/CursorX_0.1.0.zip) |
| MFCMouseEffect | 0.1.0 | 25 | 48.9 KB | [下载](https://gitee.com/qiuzongman/CurSeen-Scripts/releases/download/MFCMouseEffect_0.1.0/MFCMouseEffect_0.1.0.zip) | [下载](https://github.com/zongmanqiu/CurSeen-Scripts/releases/download/MFCMouseEffect_0.1.0/MFCMouseEffect_0.1.0.zip) |
| MouseEffects | 0.1.0 | 33 | 67.4 KB | [下载](https://gitee.com/qiuzongman/CurSeen-Scripts/releases/download/MouseEffects_0.1.0/MouseEffects_0.1.0.zip) | [下载](https://github.com/zongmanqiu/CurSeen-Scripts/releases/download/MouseEffects_0.1.0/MouseEffects_0.1.0.zip) |

**机器清单**：[`scripts.json`](scripts.json)（宿主从两个镜像的 `main` 分支读取）：

- Gitee：`https://gitee.com/qiuzongman/CurSeen-Scripts/raw/main/scripts.json`
- GitHub：`https://raw.githubusercontent.com/zongmanqiu/CurSeen-Scripts/main/scripts.json`

## 怎么用

1. CurSeen → **设置** → 展开「**官方资源下载**」→ 点「**刷新**」。
2. 行尾按钮：蓝色「下载」= 没装；橙色「升级」= 本机是旧版；灰色「下载」= 已是最新、
   当前镜像没地址、或包要求更高的宿主。下载中按钮显示百分比。
3. 装完脚本页会自动出现对应卡片（开关在那张卡上）；想卸载就点同行的「**!**」，
   在「资源包信息」窗底部「卸载」（两段式确认）。
4. 两个镜像都拉不到时，宿主用上次缓存的清单；**已装的包仍能看到、也能卸载**。

★ **出厂联动**：这四个包同时也是 CurSeen 的出厂脚本。宿主启动时会把盘上的出厂目录
认领成 `v0.0.0` 的安装记录，所以在线上包才能覆盖/更新/卸载出厂那份（只写记录，不动文件）。

## 目录

| 想知道 | 去哪 |
|---|---|
| 包格式、清单字段、版本与发版步骤 | [`开发指南.md`](开发指南.md) |
| 打 zip（输出到仓库外）、回写体积 | [`tools/build_packs.py`](tools/build_packs.py) |
| 上传后自检（清单 + 四个下载地址） | [`tools/check_remote.py`](tools/check_remote.py) |
| 机器清单（宿主直接读） | [`scripts.json`](scripts.json) |
| 四个包的源码与各自的 LICENSE / README | [`MouseEffect/`](MouseEffect/) |
| 第三方来源与许可 | [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md) |
| 本仓库许可（AGPL-3.0 全文） | [`LICENSE`](LICENSE) |

## 包格式（一眼版）

```text
CursorFX_0.1.0.zip
├─ pack.json   { id, name, version, files: ["scripts/CursorFX/animals.lua", …] }
├─ LICENSE     随包手续（宿主强制要求）
├─ README.md   随包手续（宿主强制要求）
├─ HISTORY.md  随包手续（宿主强制要求；含 `## <版本>` 历史段）
└─ files/scripts/CursorFX/…   ← 与 assets/lua/ 同构，装的时候整棵搬过去
```

详细的字段、校验与冲突规则见 [`开发指南.md`](开发指南.md)。

## 构建与发布

```bash
python tools/build_packs.py          # 打到仓库外 ../.temp/curseen-scripts-dist，并回写体积
python tools/build_packs.py --check  # 只校验源目录/清单/地址
python tools/check_remote.py         # 上传后自检：清单可达 + 四个 zip 真能下、体积对
```

发版：把仓库外打出的 `<id>_<version>.zip` 传到 **Gitee 与 GitHub 的 release**（tag 与资产同名，
形如 `CursorFX_0.1.0`），再把 `scripts.json` 推到两边的 **`main`** 分支。宿主按
`<id>_<version>` 的 tag 拼下载地址；地址格式不对时打包脚本会直接拒绝。

> ★ **默认分支必须是 `main`**：宿主读的是 `raw/main/scripts.json`。Gitee 新仓库若默认
> `master`，要么把默认分支改成 `main`，要么把宿主 `config.json` 的 `store` 两条地址改成 `master`。
>
> ⚠ 首次发版前四个地址打不开：Gitee 对不存在的 release 资产会回 **200 + HTML 错误页**，
> 所以自检工具看的是 **zip 魔数与真实体积**，不是状态码。宿主此时会如实报"拉取清单失败"。
> 上传后跑一遍 `python tools/check_remote.py`，Gitee 全 OK 再进宿主点「刷新」。

## 许可证

本仓库 **AGPL-3.0**（[`LICENSE`](LICENSE)）。四个包是对上游项目的**独立 Lua 重实现**，
未复制上游源码/素材；上游名称、链接与许可见 [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md)
与各包自己的 `README.md` / `LICENSE`。
