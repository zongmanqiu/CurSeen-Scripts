#!/usr/bin/env python3
"""上传后自检：清单可达吗？全部下载地址真的能下、体积对得上吗？

用法（在仓库根）：
    python tools/check_remote.py           # Gitee 必过；GitHub 未镜像只告警
    python tools/check_remote.py --strict  # 两个镜像都必须过

判据：
- 清单：GET 两边的 raw `scripts.json`，200 且能解析出与本地**同名同版本**的条目；
- 资产：GET 整个 zip，校验开头是 `PK`（zip 头）且**真实长度 == 本地 size**。
  ★ 不能只看状态码：Gitee 对不存在的 release 资产会回 200 + HTML 错误页（实测）。
- Gitee 是默认来源，它失败 ⇒ 退出码 1；GitHub 只在 `--strict` 下算失败。

只用标准库，不读任何凭据。
"""

import argparse
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "scripts.json"
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) CurSeen/2.0"
TIMEOUT = 30
ZIP_MAGIC = b"PK\x03\x04"


def http(url: str, method: str = "GET"):
    req = urllib.request.Request(url, method=method, headers={"User-Agent": UA})
    return urllib.request.urlopen(req, timeout=TIMEOUT)


def check_catalog(url: str, local: dict):
    """返回 (ok, 说明)。"""
    try:
        with http(url) as r:
            if r.status != 200:
                return False, f"HTTP {r.status}"
            text = r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return False, f"HTTP {e.code}"
    except Exception as e:  # noqa: BLE001 - 网络错误统一报一句
        return False, f"不可达：{e}"
    try:
        remote = json.loads(text)
    except ValueError as e:
        return False, f"不是合法 JSON：{e}"
    if not isinstance(remote, list):
        return False, "根节点不是数组"
    by_id = {e.get("id"): e for e in remote if isinstance(e, dict)}
    problems = []
    for pid, want in local.items():
        got = by_id.get(pid)
        if got is None:
            problems.append(f"缺 {pid}")
            continue
        if str(got.get("version")) != str(want["version"]):
            problems.append(f"{pid} 版本 {got.get('version')} ≠ {want['version']}")
        elif int(got.get("size") or 0) != int(want["size"]):
            # ★ 版本号相同也可能是旧清单（历史包重打过、体积变了）：按体积再判一道。
            problems.append(f"{pid} 体积 {got.get('size')} ≠ {want['size']}")
        elif got.get("urls") != want.get("urls"):
            problems.append(f"{pid} 下载地址与本地不一致")
    extra = [pid for pid in by_id if pid not in local]
    if extra:
        problems.append("多出：" + ", ".join(sorted(extra)))
    if problems:
        return False, "；".join(problems)
    return True, f"{len(remote)} 条，与本地同名同版本"


def check_asset(url: str, size: int):
    """返回 (ok, 说明)。读回整个 zip，按魔数与真实长度判定。"""
    try:
        with http(url) as r:
            if r.status != 200:
                return False, f"HTTP {r.status}"
            body = r.read()
    except urllib.error.HTTPError as e:
        return False, f"HTTP {e.code}"
    except Exception as e:  # noqa: BLE001
        return False, f"不可达：{e}"
    if not body.startswith(ZIP_MAGIC):
        head = body[:16].decode("utf-8", "replace").replace("\n", " ").replace("\r", " ")
        return False, f"返回的不是 zip（{len(body)} B，开头 {head!r}）——多半还没发布"
    if len(body) != size:
        return False, f"体积 {len(body)} ≠ 本地 {size}"
    return True, f"200，{len(body)} B，zip 头正确"


def catalog_urls(entries):
    """从条目里的 gitee/github 下载地址推导两个 raw 清单地址（与宿主默认同一形状）。"""
    roots = {}
    for host in ("gitee", "github"):
        sample = next((e["urls"][host] for e in entries if e["urls"].get(host)), "")
        if not sample:
            continue
        base = sample.split("/releases/download/")[0]
        if host == "gitee":
            roots[host] = base + "/raw/main/scripts.json"
        else:
            # https://github.com/<owner>/<repo> → raw.githubusercontent.com/<owner>/<repo>/main/…
            tail = base.split("github.com/", 1)[-1]
            roots[host] = f"https://raw.githubusercontent.com/{tail}/main/scripts.json"
    return roots


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--strict", action="store_true", help="GitHub 镜像也必须可达")
    args = ap.parse_args()

    entries = json.loads(CATALOG.read_text(encoding="utf-8"))
    local = {e["id"]: e for e in entries}
    failed = False

    print("== 清单 ==")
    roots = catalog_urls(entries)
    for host in ("gitee", "github"):
        url = roots.get(host, "")
        if not url:
            print(f"[{host}] 清单未配置")
            continue
        ok, note = check_catalog(url, local)
        print(f"[{host}] {'OK ' if ok else 'FAIL'} {note}\n        {url}")
        if not ok and (host == "gitee" or args.strict):
            failed = True

    print("\n== 下载地址 ==")
    for host in ("gitee", "github"):
        for e in entries:
            url = e["urls"].get(host, "")
            if not url:
                print(f"[{host}] {e['id']}: 未配置")
                continue
            ok, note = check_asset(url, int(e["size"]))
            print(f"[{host}] {e['id']}: {'OK ' if ok else 'FAIL'} {note}")
            if not ok and (host == "gitee" or args.strict):
                failed = True

    print()
    if failed:
        print("存在失败项（Gitee 为默认来源，失败即不可用）。")
        sys.exit(1)
    print("自检通过：宿主默认来源可拉清单、全部包都可下载且体积一致。")


if __name__ == "__main__":
    main()
