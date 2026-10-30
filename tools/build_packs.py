#!/usr/bin/env python3
"""把 MouseEffect/<包>/ 或 Packs/<包>/ 打成 CurSeen 商店包（zip），并把体积回写 scripts.json。

★ 本仓库**只放源码**：源码包与官方工具源码都在仓库里；编译产物（exe/模型）由
`tools/<tool>/build.ps1` 生成到仓库外（默认 `../.temp/curseen-tools/<tool>`），
zip 也在仓库外（默认 `../.temp/curseen-scripts-dist`）。

用法：
    python tools/build_packs.py           # 打包 + 回写 size
    python tools/build_packs.py --check   # 只校验源目录/清单/地址，不写任何文件
    python tools/build_packs.py --out D:/tmp/packs --tool-root D:/tmp/tools

包的形状（与宿主 `scripting/store.rs` 一一对应）：

    <id>_<version>.zip
    ├─ pack.json   { id, name, version, files: ["scripts/…", …] }
    ├─ LICENSE     来自源目录
    ├─ README.md   来自源目录
    ├─ HISTORY.md  来自源目录（必须含 `## <version>` 段）
    └─ files/…     .lua；另有每个包的文档夹 `scripts/<id>_<version>/`（LICENSE/README/HISTORY）；
                   有官方工具的包再加 `scripts/<tool_dest>/…`

清单 `scripts.json` 的字段（宿主读其中 id/name/version/size/description/urls/min_host/
    author/license/released/api/unpacked_size/file_count）：
    id / name / version / description / size（字节，本脚本回写）/
    author / license / released / api（打包校验）/
    unpacked_size / file_count（本脚本按实际文件（含文档夹/工具）实算并回写）/
    dir（源目录，仅本脚本用）/ mount（Packs 包固定 "scripts"）/
    tool（可选：`../.temp/curseen-tools/<tool>` 下的官方工具目录）/
    tool_dest（有 tool 时必填：装到 `scripts/<tool_dest>`）/
    urls.gitee / urls.github（release 资产地址，tag = `<id>_<version>`）
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


def lua_files(src: Path):
    files = sorted(p for p in src.rglob("*.lua") if p.is_file())
    if not files:
        fail(f"{src} 下没有 .lua")
    return files


def safe_dest(dest: str) -> None:
    p = PurePosixPath(dest)
    if p.is_absolute() or ".." in p.parts or ":" in dest:
        fail(f"tool_dest 不安全：{dest}")
    if len(p.parts) < 2 or p.parts[0] != "scripts":
        fail(f"tool_dest 必须落在 scripts/ 下：{dest}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只校验，不写 zip/清单")
    ap.add_argument("--out", default=str(DEFAULT_OUT), help=f"zip 输出目录（默认 {DEFAULT_OUT}）")
    ap.add_argument(
        "--tool-root",
        default=str(DEFAULT_TOOL_ROOT),
        help=f"官方工具构建输出根目录（默认 {DEFAULT_TOOL_ROOT}）",
    )
    args = ap.parse_args()
    out_dir = Path(args.out)
    tool_root = Path(args.tool_root)

    entries = json.loads(CATALOG.read_text(encoding="utf-8"))
    if not isinstance(entries, list) or not entries:
        fail("scripts.json 必须是非空数组")

    seen = set()
    owned = {}
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

        src = ROOT / e["dir"]
        if not src.is_dir():
            fail(f"源目录不存在：{src}")
        if src.parent.name not in ("MouseEffect", "Packs"):
            fail(f"源目录必须在 MouseEffect/ 或 Packs/ 下：{src}")
        mount = e.get("mount")
        if src.parent.name == "MouseEffect":
            if mount is not None:
                fail(f"{pid}：MouseEffect 包不写 mount（固定 scripts/<目录>/）")
            prefix = f"scripts/{src.name}"
        else:
            if mount != "scripts":
                fail(f"{pid}：Packs 包必须写 mount=\"scripts\"")
            prefix = "scripts"
        for need in ("LICENSE", "README.md", "HISTORY.md"):
            if not (src / need).is_file():
                fail(f"{src} 缺 {need}（包必须带手续）")
        # 每个包自己的版本历史：当前 catalog 版本必须有一段 `## <version>`，
        # 否则"发版没写历史"会悄悄发生。
        history = (src / "HISTORY.md").read_text(encoding="utf-8")
        if f"## {version}" not in history:
            fail(f"{src}/HISTORY.md 缺少 `## {version}` 段（发版必须写历史）")

        sources = []  # (源文件, zip 内 files/ 下的相对路径)
        for p in lua_files(src):
            sources.append((p, f"{prefix}/{p.relative_to(src).as_posix()}"))

        # 每个官方包在安装目录里留一份**自己的文档夹**（RuPix 的 `<id>_<version>/` 同型）：
        # LICENSE / README / HISTORY 不只是 zip 根的手续，装完也找得到。
        doc_dir = f"scripts/{pid}_{version}"
        for doc in ("LICENSE", "README.md", "HISTORY.md"):
            sources.append((src / doc, f"{doc_dir}/{doc}"))

        tool = e.get("tool")
        tool_missing = False
        if tool is not None:
            tool_dest = e.get("tool_dest")
            if not tool_dest:
                fail(f"{pid}：声明了 tool 就必须写 tool_dest")
            safe_dest(tool_dest)
            tool_dir = tool_root / tool
            if not tool_dir.is_dir():
                if args.check:
                    print(f"[!] {pid}：工具目录不存在，--check 跳过工具文件：{tool_dir}")
                    tool_missing = True
                else:
                    fail(f"{pid}：工具目录不存在：{tool_dir}（先跑 tools/{tool}/build.ps1）")
            else:
                tool_files = sorted(p for p in tool_dir.rglob("*") if p.is_file())
                if not tool_files:
                    fail(f"{pid}：工具目录是空的：{tool_dir}")
                for p in tool_files:
                    sources.append((p, f"{tool_dest}/{p.relative_to(tool_dir).as_posix()}"))

        files = [rel for _, rel in sources]
        if len(files) != len(set(files)):
            fail(f"{pid} 的文件清单有重复")
        for rel in files:
            if rel in owned:
                fail(f"{pid} 要装的文件已被 {owned[rel]} 占用：{rel}")
            owned[rel] = pid

        e["unpacked_size"] = sum(p.stat().st_size for p, _ in sources)
        e["file_count"] = len(files)

        tag = f"{pid}_{version}"
        for host in ("gitee", "github"):
            url = e["urls"].get(host, "")
            if not url.startswith("https://"):
                fail(f"{pid} 的 {host} 地址必须是 https")
            if not url.endswith(f"/{tag}/{tag}.zip"):
                fail(
                    f"{pid} 的 {host} 地址结尾应为 /{tag}/{tag}.zip（tag 与资产同名）：{url}"
                )

        zip_path = out_dir / f"{tag}.zip"
        if not args.check:
            out_dir.mkdir(parents=True, exist_ok=True)
            meta = {"id": pid, "name": name, "version": version, "files": files}
            with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
                z.writestr("pack.json", json.dumps(meta, ensure_ascii=False, indent=2) + "\n")
                z.write(src / "LICENSE", "LICENSE")
                z.write(src / "README.md", "README.md")
                z.write(src / "HISTORY.md", "HISTORY.md")
                for p, rel in sources:
                    z.write(p, "files/" + rel)
            e["size"] = zip_path.stat().st_size

        size_text = f"{e['size'] / 1024:.1f} KB" if e.get("size") else "（未打包）"
        tool_text = " + 官方工具" if tool is not None and not tool_missing else ""
        print(f"[{pid}] v{version}  {len(files)} 个文件{tool_text}  {size_text}  → {zip_path}")

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
