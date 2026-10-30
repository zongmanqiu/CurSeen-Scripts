# CurSeen 脚本仓库

> **仓库入口**：[**Gitee**](https://gitee.com/qiuzongman/CurSeen-Scripts) | [**GitHub**](https://github.com/zongmanqiu/CurSeen-Scripts)

CurSeen 的**脚本包**来源：每个包是一份 zip，解压后就是一个稳定的包文件夹
（`assets/lua/scripts/<id>/`），由宿主「设置 → 官方资源下载」列出、下载、更新、卸载。
八个包全部平铺在 [`Packs/`](Packs/) 下：四个鼠标特效、AI 写脚本、图片体检、
OCR 文字识别与条码识别。

★ 本仓库**只放源码**：打包出来的 zip 不提交、不进仓库（生成到仓库外 `../.temp/curseen-scripts-dist/`）。
版本从 **0.1.0** 起；出厂包在宿主里认领为 `v0.0.0`，所以首个在线版本仍会显示为「升级」。

## 发布包

| 包 | 版本 | 发行时间 | 文件数 | 体积 | Gitee | GitHub |
|---|---:|---|---:|---:|---|---|
| CursorFX | 0.2.0 | 2026-10-30 | 46 | 96.2 KB | [下载](https://gitee.com/qiuzongman/CurSeen-Scripts/releases/download/CursorFX_0.2.0/CursorFX_0.2.0.zip) | [下载](https://github.com/zongmanqiu/CurSeen-Scripts/releases/download/CursorFX_0.2.0/CursorFX_0.2.0.zip) |
| CursorX | 0.2.0 | 2026-10-30 | 28 | 50.7 KB | [下载](https://gitee.com/qiuzongman/CurSeen-Scripts/releases/download/CursorX_0.2.0/CursorX_0.2.0.zip) | [下载](https://github.com/zongmanqiu/CurSeen-Scripts/releases/download/CursorX_0.2.0/CursorX_0.2.0.zip) |
| MFCMouseEffect | 0.2.0 | 2026-10-30 | 29 | 49.3 KB | [下载](https://gitee.com/qiuzongman/CurSeen-Scripts/releases/download/MFCMouseEffect_0.2.0/MFCMouseEffect_0.2.0.zip) | [下载](https://github.com/zongmanqiu/CurSeen-Scripts/releases/download/MFCMouseEffect_0.2.0/MFCMouseEffect_0.2.0.zip) |
| MouseEffects | 0.2.0 | 2026-10-30 | 37 | 67.6 KB | [下载](https://gitee.com/qiuzongman/CurSeen-Scripts/releases/download/MouseEffects_0.2.0/MouseEffects_0.2.0.zip) | [下载](https://github.com/zongmanqiu/CurSeen-Scripts/releases/download/MouseEffects_0.2.0/MouseEffects_0.2.0.zip) |
| AI 写脚本 | 0.1.0 | 2026-10-30 | 6 | 23.1 KB | [下载](https://gitee.com/qiuzongman/CurSeen-Scripts/releases/download/AI_0.1.0/AI_0.1.0.zip) | [下载](https://github.com/zongmanqiu/CurSeen-Scripts/releases/download/AI_0.1.0/AI_0.1.0.zip) |
| 图片体检 | 0.2.0 | 2026-10-30 | 5 | 7.8 KB | [下载](https://gitee.com/qiuzongman/CurSeen-Scripts/releases/download/ImageReport_0.2.0/ImageReport_0.2.0.zip) | [下载](https://github.com/zongmanqiu/CurSeen-Scripts/releases/download/ImageReport_0.2.0/ImageReport_0.2.0.zip) |
| OCR 文字识别 | 0.3.0 | 2026-10-30 | 10 | 20.2 MB | [下载](https://gitee.com/qiuzongman/CurSeen-Scripts/releases/download/OCR_0.3.0/OCR_0.3.0.zip) | [下载](https://github.com/zongmanqiu/CurSeen-Scripts/releases/download/OCR_0.3.0/OCR_0.3.0.zip) |
| 条码识别 | 0.2.0 | 2026-10-30 | 6 | 756.8 KB | [下载](https://gitee.com/qiuzongman/CurSeen-Scripts/releases/download/Barcode_0.2.0/Barcode_0.2.0.zip) | [下载](https://github.com/zongmanqiu/CurSeen-Scripts/releases/download/Barcode_0.2.0/Barcode_0.2.0.zip) |

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

★ **出厂联动**：四个鼠标特效包同时也是 CurSeen 的出厂脚本，宿主启动时会把盘上的
出厂目录认领成 `v0.0.0` 的安装记录，所以在线上包才能覆盖/更新/卸载出厂那份（只写记录，
不动文件）。AI 写脚本 / 图片体检 / OCR / 条码识别包**不再内置**；所有在线包都装进自己的
稳定文件夹 `assets/lua/scripts/<id>/`（脚本与同目录资料平铺、`info/` 放文档，记录写在
文件夹里的 `.curseen-pack.json`）。OCR 文字识别与条码识别包自带官方工具，装包即用。

## 目录

| 想知道 | 去哪 |
|---|---|
| 包格式、清单字段、版本与发版步骤 | [`开发指南.md`](开发指南.md) |
| 打 zip（输出到仓库外）、回写体积 | [`tools/build_packs.py`](tools/build_packs.py) |
| 上传后自检（清单 + 全部下载地址） | [`tools/check_remote.py`](tools/check_remote.py) |
| 机器清单（宿主直接读） | [`scripts.json`](scripts.json) |
| 八个官方包的源码与各自的 LICENSE / README | [`Packs/`](Packs/) |
| 官方 OCR / 条码工具的源码、构建脚本与上游版本锁 | [`tools/`](tools/) |
| 第三方来源与许可 | [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md) |
| 本仓库许可（AGPL-3.0 全文） | [`LICENSE`](LICENSE) |

## 包格式（一眼版）

```text
CursorFX_0.2.0.zip
└─ CursorFX/                 ← 解压到 assets/lua/scripts/ 后就是稳定包文件夹
   ├─ pack.json              ← { id, name, version, layout: 2, files: [...] }
   ├─ *                      ← 脚本与同目录资料平铺在包根（至少一个 .lua）
   ├─ info/
   │  ├─ LICENSE
   │  ├─ README.md
   │  └─ HISTORY.md          ← 含 `## <版本>` 历史段
   └─ <tool_dest>/…          ← 官方工具（OCR / 条码包才有）
```

升级 = **整个包文件夹替换**：旧文件夹先整体挪开，新文件夹落到原位，再把旧文件清掉；
不会出现"只覆盖同名文件、改名后的旧脚本残留"的问题。包外的用户脚本/内置脚本一个不动。

详细的字段、校验与冲突规则见 [`开发指南.md`](开发指南.md)。

## 构建与发布

```bash
python tools/build_packs.py          # 打到仓库外 ../.temp/curseen-scripts-dist，并回写体积
python tools/build_packs.py --check  # 只校验源目录/清单/地址
python tools/check_remote.py         # 上传后自检：清单可达 + 全部 zip 真能下、体积对
```

发版：把仓库外打出的 `<id>_<version>.zip` 传到 **Gitee 与 GitHub 的 release**（tag 与资产同名，
形如 `CursorFX_0.1.0`），再把 `scripts.json` 推到两边的 **`main`** 分支。宿主按
`<id>_<version>` 的 tag 拼下载地址；地址格式不对时打包脚本会直接拒绝。

> ★ **默认分支必须是 `main`**：宿主读的是 `raw/main/scripts.json`。Gitee 新仓库若默认
> `master`，要么把默认分支改成 `main`，要么把宿主 `config.json` 的 `store` 两条地址改成 `master`。
>
> ⚠ 首次发版前这些地址打不开：Gitee 对不存在的 release 资产会回 **200 + HTML 错误页**，
> 所以自检工具看的是 **zip 魔数与真实体积**，不是状态码。宿主此时会如实报"拉取清单失败"。
> 上传后跑一遍 `python tools/check_remote.py`，Gitee 全 OK 再进宿主点「刷新」。

## 许可证

本仓库 **AGPL-3.0**（[`LICENSE`](LICENSE)）。四个鼠标特效包是对上游项目的**独立 Lua 重实现**，
未复制上游源码/素材；上游名称、链接与许可见 [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md)
与各包自己的 `README.md` / `LICENSE`。
