#!/usr/bin/env python3
"""把 MouseEffect/<包>/ 打成 CurSeen 商店包（zip），并把体积回写 scripts.json。

★ 本仓库**只放源码**：zip 一律生成到仓库**外**（默认 `../.temp/curseen-scripts-dist`，
`--out` 可改），不发进仓库、不需要提交。

用法：
    python tools/build_packs.py           # 打包 + 回写 size
    python tools/build_packs.py --check   # 只校验源目录/清单/地址，不写任何文件
    python tools/build_packs.py --out D:/tmp/packs

包的形状（与宿主 `scripting/store.rs` 一一对应）：

    <id>_<version>.zip
    ├─ pack.json   { id, name, version, files: ["scripts/<目录>/x.lua", …] }
    ├─ LICENSE     来自源目录
    ├─ README.md   来自源目录
    ├─ HISTORY.md  来自源目录（必须含 `## <version>` 段）
    └─ files/scripts/<目录>/…   只有 .lua（源目录里的 pack.json 等手续不装进脚本目录）

清单 `scripts.json` 的字段（宿主读其中 id/name/version/size/description/urls/min_host）：
    id / name / version / description / size（字节，本脚本回写）/
    min_host（宿主最低版本）/ dir（源目录，仅本脚本用）/
    urls.gitee / urls.github（release 资产地址，tag = `<id>_<version>`）
"""

import argparse
import json
import os
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "scripts.json"
DEFAULT_OUT = ROOT.parent / ".temp" / "curseen-scripts-dist"

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


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只校验，不写 zip/清单")
    ap.add_argument("--out", default=str(DEFAULT_OUT), help=f"zip 输出目录（默认 {DEFAULT_OUT}）")
    args = ap.parse_args()
    out_dir = Path(args.out)

    entries = json.loads(CATALOG.read_text(encoding="utf-8"))
    if not isinstance(entries, list) or not entries:
        fail("scripts.json 必须是非空数组")

    seen = set()
    for e in entries:
        for key in ("id", "name", "version", "description", "dir", "urls"):
            if key not in e:
                fail(f"清单项缺 {key}：{e}")
        pid, name, version = e["id"], e["name"], e["version"]
        if not ID_RE.match(pid):
            fail(f"id 不合法：{pid}")
        if not VERSION_RE.match(version):
            fail(f"版本号不合法：{pid} {version}")
        if pid in seen:
            fail(f"id 重复：{pid}")
        seen.add(pid)

        src = ROOT / e["dir"]
        if not src.is_dir():
            fail(f"源目录不存在：{src}")
        if src.parent.name != "MouseEffect":
            fail(f"源目录必须在 MouseEffect/ 下：{src}")
        for need in ("LICENSE", "README.md", "HISTORY.md"):
            if not (src / need).is_file():
                fail(f"{src} 缺 {need}（包必须带手续）")
        # 每个包自己的版本历史：当前 catalog 版本必须有一段 `## <version>`，
        # 否则"发版没写历史"会悄悄发生。
        history = (src / "HISTORY.md").read_text(encoding="utf-8")
        if f"## {version}" not in history:
            fail(f"{src}/HISTORY.md 缺少 `## {version}` 段（发版必须写历史）")

        lua = lua_files(src)
        files = [f"scripts/{src.name}/{p.relative_to(src).as_posix()}" for p in lua]
        if len(files) != len(set(files)):
            fail(f"{pid} 的文件清单有重复")

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
                for p, rel in zip(lua, files):
                    z.write(p, "files/" + rel)
            e["size"] = zip_path.stat().st_size

        size_text = f"{e['size'] / 1024:.1f} KB" if e.get("size") else "（未打包）"
        print(f"[{pid}] v{version}  {len(files)} 个脚本  {size_text}  → {zip_path}")

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
