#!/usr/bin/env python3
"""把 Packs/<包>/ 打成 CurSeen 商店包（zip），并把体积回写 scripts.json。

包结构（2026-10-30 定案，v2）：

    <id>_<version>.zip
    └─ <id>/                     ← 解压到 assets/lua/scripts 后就是稳定包文件夹
       ├─ pack.json              ← 包配置（下拉/默认项/版本）
       ├─ *                       ← 脚本/资料平铺（来自源目录 scripts/，至少一个 .lua）
       ├─ <tool_dest>/…          ← 官方工具（如有；来自仓外构建输出）
       └─ info/
          ├─ LICENSE
          ├─ README.md
          └─ HISTORY.md

仓库只放源码：编译产物与模型由 `tools/<tool>/build.ps1` 生成到仓外
（默认 `../.temp/curseen-tools/<tool>`）；zip 输出到仓外（默认
`../.temp/curseen-scripts-dist`）。升级按整个包文件夹替换。

★ 2026-10-31 用户口径：**每次只打包被改的那个资源**。所以必须显式二选一：
    python tools/build_packs.py --id AI     # 只重建 AI 的 zip + 只回写 AI 的清单字段
    python tools/build_packs.py --all       # 发版时才允许全量重建
不指定会直接拒绝；被跳过的包只做结构校验，不生成 zip、不改体积字段。
"""

import argparse
import json
import os
import re
import sys
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "scripts.json"
DEFAULT_OUT = ROOT.parent / ".temp" / "curseen-scripts-dist"
DEFAULT_TOOL_ROOT = ROOT.parent / ".temp" / "curseen-tools"

ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$")
VERSION_RE = re.compile(r"^\d+(\.\d+)*$")


def fail(msg: str) -> None:
    print(f"[x] {msg}", file=sys.stderr)
    sys.exit(1)


def safe_rel(rel: str, what: str) -> None:
    p = PurePosixPath(rel)
    if p.is_absolute() or ".." in p.parts or ":" in rel or not p.parts:
        fail(f"{what} 不安全：{rel}")


def payload_files(src: Path):
    d = src / "scripts"
    files = sorted(p for p in d.rglob("*") if p.is_file())
    if not any(p.suffix == ".lua" for p in files):
        fail(f"{d} 下没有 .lua（v2 包必须把脚本放在 scripts/ 下）")
    return files


def package_entries(src: Path, e: dict, tool_root: Path, check: bool):
    """返回 (源文件, 包内相对路径) 列表；不含生成的 pack.json。"""
    entries = []
    for doc in ("LICENSE", "README.md", "HISTORY.md"):
        p = src / "info" / doc
        if not p.is_file():
            fail(f"{src} 缺 info/{doc}（包必须带手续）")
        entries.append((p, f"info/{doc}"))

    for p in payload_files(src):
        rel = p.relative_to(src / "scripts").as_posix()
        safe_rel(rel, "脚本路径")
        entries.append((p, rel))

    tool = e.get("tool")
    if tool is not None:
        dest = e.get("tool_dest")
        if not dest:
            fail(f"{e['id']}：声明了 tool 就必须写 tool_dest")
        safe_rel(dest, "tool_dest")
        if PurePosixPath(dest).parts[0] in ("info", "scripts") or dest == "pack.json":
            fail(f"{e['id']}：tool_dest 不能占用 info/scripts/pack.json：{dest}")
        tool_dir = tool_root / tool
        if not tool_dir.is_dir():
            if check:
                print(f"[!] {e['id']}：工具目录不存在，--check 跳过工具文件：{tool_dir}")
            else:
                fail(f"{e['id']}：工具目录不存在：{tool_dir}（先跑 tools/{tool}/build.ps1）")
        else:
            files = sorted(p for p in tool_dir.rglob("*") if p.is_file())
            if not files:
                fail(f"{e['id']}：工具目录是空的：{tool_dir}")
            for p in files:
                rel = f"{dest}/{p.relative_to(tool_dir).as_posix()}"
                safe_rel(rel, "工具路径")
                entries.append((p, rel))
    return entries


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只校验，不写 zip/清单")
    ap.add_argument(
        "--id",
        action="append",
        default=[],
        help="只处理这些包 id（可重复，或逗号分隔）；与 --all 二选一，必须显式给",
    )
    ap.add_argument("--all", action="store_true", help="全量重建（发版用）")
    ap.add_argument("--out", default=str(DEFAULT_OUT), help=f"zip 输出目录（默认 {DEFAULT_OUT}）")
    ap.add_argument(
        "--tool-root",
        default=str(DEFAULT_TOOL_ROOT),
        help=f"官方工具构建输出根目录（默认 {DEFAULT_TOOL_ROOT}）",
    )
    args = ap.parse_args()
    out_dir = Path(args.out)
    tool_root = Path(args.tool_root)

    requested: list[str] = []
    for item in args.id:
        requested.extend(x.strip() for x in item.split(",") if x.strip())
    if args.all and requested:
        fail("--id 与 --all 只能二选一")
    if not args.all and not requested:
        fail("请显式指定 --id <包> 或 --all（防止改一个包时重建全部资源）")

    entries = json.loads(CATALOG.read_text(encoding="utf-8"))
    if not isinstance(entries, list) or not entries:
        fail("scripts.json 必须是非空数组")

    all_ids = {e.get("id") for e in entries if isinstance(e.get("id"), str)}
    selected = set(all_ids) if args.all else set(requested)
    unknown = sorted(selected - all_ids)
    if unknown:
        fail(f"未知包 id：{unknown}（清单里有 {sorted(all_ids)}）")
    print(f"只处理：{sorted(selected)}（其余包仅做基础校验，不生成 zip / 不改体积）")

    seen = set()
    for e in entries:
        for key in ("id", "name", "version", "description", "dir", "urls",
                    "author", "license", "released", "api"):
            if key not in e:
                fail(f"清单项缺 {key}：{e}")
        pid, name, version = e["id"], e["name"], e["version"]
        if not ID_RE.match(pid):
            fail(f"id 不合法：{pid}")
        if not VERSION_RE.match(version):
            fail(f"版本号不合法：{pid} {version}")
        if not re.match(r"^\d{4}-\d{2}-\d{2}$", str(e["released"])):
            fail(f"{pid} 的 released 必须是 YYYY-MM-DD")
        if not isinstance(e["api"], int) or e["api"] < 0:
            fail(f"{pid} 的 api 必须是非负整数")
        if pid in seen:
            fail(f"id 重复：{pid}")
        seen.add(pid)

        # ★ 未被 --id 选中的包：只做上面的基础清单校验，绝不生成 zip / 改体积。
        if pid not in selected:
            continue

        src = ROOT / e["dir"]
        if not src.is_dir():
            fail(f"源目录不存在：{src}")
        if src.parent.name != "Packs":
            fail(f"源目录必须在 Packs/ 下：{src}")
        pack_src = src / "pack.json"
        if not pack_src.is_file():
            fail(f"{src} 缺 pack.json")
        if not (src / "scripts").is_dir() or not (src / "info").is_dir():
            fail(f"{src} 必须是 scripts/ + info/ + pack.json 的结构")

        history = (src / "info" / "HISTORY.md").read_text(encoding="utf-8")
        if f"## {version}" not in history:
            fail(f"{src}/info/HISTORY.md 缺少 `## {version}` 段（发版必须写历史）")

        entries_for_zip = package_entries(src, e, tool_root, args.check)
        rels = ["pack.json"] + [rel for _, rel in entries_for_zip]
        if len(rels) != len(set(rels)):
            fail(f"{pid} 的文件清单有重复")

        meta = json.loads(pack_src.read_text(encoding="utf-8"))
        meta.update({
            "id": pid,
            "name": name,
            "version": version,
            "layout": 2,
            "files": sorted(rels),
        })
        meta_text = json.dumps(meta, ensure_ascii=False, indent=2) + "\n"
        folder = pid

        tag = f"{pid}_{version}"
        for host in ("gitee", "github"):
            url = e["urls"].get(host, "")
            if not url.startswith("https://"):
                fail(f"{pid} 的 {host} 地址必须是 https")
            if not url.endswith(f"/{tag}/{tag}.zip"):
                fail(
                    f"{pid} 的 {host} 地址结尾应为 /{tag}/{tag}.zip（tag 与资产同名）：{url}"
                )

        e["unpacked_size"] = sum(p.stat().st_size for p, _ in entries_for_zip) + len(meta_text.encode())
        e["file_count"] = len(rels)

        zip_path = out_dir / f"{tag}.zip"
        if not args.check:
            out_dir.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
                z.writestr(f"{folder}/pack.json", meta_text)
                for p, rel in entries_for_zip:
                    z.write(p, f"{folder}/{rel}")
            e["size"] = zip_path.stat().st_size

        size_text = f"{e['size'] / 1024:.1f} KB" if e.get("size") else "（未打包）"
        print(f"[{pid}] v{version}  {len(rels)} 个文件  {size_text}  → {zip_path}")

    if args.check:
        print("校验通过（未写文件）")
        return

    tmp = CATALOG.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(entries, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, CATALOG)
    print(f"已回写体积：{CATALOG}")
    print(f"zip 输出在仓库外：{out_dir}")
    print("下一步：把 zip 传到 Gitee / GitHub 的 release（tag = <id>_<version>），")
    print("        再把 scripts.json 推到两边的 main 分支。")


if __name__ == "__main__":
    main()
