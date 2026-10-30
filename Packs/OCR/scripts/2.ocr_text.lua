-- OCR：用外置离线引擎识别贴图/剪贴板截图里的文字，输出到宿主的文本窗，并**默认把结果
-- 复制进剪贴板**（脚本页那个勾可以关掉）。
-- 用法：贴图上点右键 → 脚本 → OCR。
--
-- ★ OCR 是一体的：只有一个脚本、一个菜单项，不再有单独的「OCR 后处理」。
--
-- 引擎只有一个：**官方随包分发的离线 OCR 工具**，放在脚本目录的 `ocr_tool\` 里。
-- 走的是宿主开放的 `ext:proc`：只允许起**脚本自己目录里的 .exe**，本体的体积与依赖一点没变
-- （不联网、不装服务、dll 与模型都跟着工具放在 `ocr_tool\` 下）。
-- 系统自带的 OCR（WinRT `Windows.Media.Ocr`）**已弃用**：中英混排会把 `别` 这类字拆成
-- "另 + 刂"，实测 20 张样本行命中只有 65%，认了不如不认。
--
-- 没装引擎会怎样：`requires` 里列的文件缺任何一个，**这一项就不出现在右键菜单里**——
-- 不做一个"点了必然失败"的菜单项。快捷键那条不挡（那份名单从配置派生，不该为可见性去扫盘），
-- 但按下去 `ext:proc` 会当场给"找不到 ./ocr_tool/CurSeenOcr.exe"这句原因，不会空跑一次。
-- 失败一定给原因（超时、退出码、输出格式变了），不静默回空串。

name = "OCR 文字识别"
category = "text"
role = "image"
menu = "OCR 文字识别"

-- ★ 条件可见的声明：这些相对脚本目录的路径**缺一个就不显示菜单项**。
--   判据由宿主算（`scripting::registry_ext` → `fs_api::resolve`），与 `ext:proc` 同一条路径判据。
--   宿主每次右键都重扫，所以放好文件不必重启。
requires = {
  "./ocr_tool/CurSeenOcr.exe",
  "./ocr_tool/ch_PP-OCRv4_det_mobile.onnx",
  "./ocr_tool/ch_PP-OCRv4_rec_mobile.onnx",
  "./ocr_tool/ch_ppocr_mobile_v2.0_cls_mobile.onnx",
  "./ocr_tool/ppocr_keys_v1.txt",
}

-- 外置引擎的位置：全部是**相对脚本目录**的路径（`ext:proc` 只认这种写法）。
-- 目录形状（官方 OCR 包装好即用；这里是工具文件清单）：
--   scripts\OCR\2.ocr_text.lua
--   scripts\OCR\ocr_tool\CurSeenOcr.exe         ← 官方工具（静态链着 onnxruntime）
--   scripts\OCR\ocr_tool\*.onnx / *.txt         ← 模型与字典（-d . 按 exe 同目录找）
local TOOL = {
  exe  = "./ocr_tool/CurSeenOcr.exe",
  det  = "ch_PP-OCRv4_det_mobile.onnx",
  cls  = "ch_ppocr_mobile_v2.0_cls_mobile.onnx",
  rec  = "ch_PP-OCRv4_rec_mobile.onnx",
  key  = "ppocr_keys_v1.txt",
  -- 一次整张识别的墙钟上限（含起进程、加载 dll 与模型）。实测单张 ~0.5 s，
  -- 20 s 是给"大图 + 冷启动 + 慢盘"留的余量，超了宿主会把它杀掉并回报 timed_out。
  timeout_ms = 20000,
  -- 输出编码：这个 CLI 实测吐 **UTF-8**（`examples/ext_proc_ocr.rs` 的臂 1b 用 true 会解成
  -- "鏂囧瓧"）。换个吐国标码的工具才把它改 true——Lua 侧没有转码能力，只有宿主能解。
  ansi = false,
}

-- 参数：复制那一项默认**开**。宿主在交棒前会把 `schema` 的 `default` 合并进 `params`（m17），
-- 所以这里读到的键一定存在；写成"只要不是显式关掉就复制"是为了把唯一那种关闭意图说清楚。
function schema()
  return {
    { key = "copy", label = "识别后复制文本", type = "bool", default = true },
    {
      -- 有快捷键就能"截图 → 按键 → 结果"，走的是宿主既有的脚本快捷键派发；
      -- 没有贴图上下文时脚本会自动改用剪贴板里的那张图。
      key = "hotkey",
      label = "快捷键",
      type = "hotkey",
    },
  }
end

--- 出结果统一收尾：先把**纯文本结果**交回剪贴板，再在窗口里补说明。
-- ★ 顺序有意义：`note`（给执行人看的解释）**不进剪贴板**——用户 Ctrl+V 要的是文字本身，
--   把中文说明一起粘出去就是给别人添麻烦。剪贴板可能被别的程序占着，那时 `ext:clip_set`
--   抛错；那不算识别失败，末尾如实说一句就行。
local function present(text, params, note)
  if params.copy ~= false then
    local ok = pcall(function() ext:clip_set(text) end)
    note = (note or "") .. (ok
      and "\n\n——（已复制到剪贴板，可直接 Ctrl+V）"
      or "\n\n——（没能写进剪贴板：可能被别的程序占着）")
  end
  return text .. (note or "")
end

--- 把 CLI 输出里的 `textLine[N](文字)` 按 N 排序拼回一段文本。
-- 只认行首的完整标记（贪婪取到行末最后一个括号），所以识别结果里带括号也不会截断。
local function parse_lines(text)
  local list = {}
  for line in text:gmatch("[^\r\n]+") do
    local n, body = line:match("^textLine%[(%d+)%]%((.*)%)%s*$")
    if n then
      list[#list + 1] = { n = tonumber(n), s = body }
    end
  end
  table.sort(list, function(a, b) return a.n < b.n end)
  local out = {}
  for i = 1, #list do out[i] = list[i].s end
  return table.concat(out, "\n")
end

--- 外置引擎一跑：位图 → 临时 PNG → CLI → 文本。返回 `text` 或 `nil, 原因`。
local function ocr_external(img)
  local png = ext:tmpdir() .. "\\ocr_in.png"
  -- save 失败是 Lua error（宿主把它抛出来的），套 pcall 换成中文原因
  local ok, err = pcall(function() img:save(png) end)
  if not ok then
    return nil, "存临时图片失败：" .. tostring(err)
  end
  local r, perr = ext:proc{
    exe  = TOOL.exe,
    -- ★ 参数是**数组**，宿主逐个交给子进程，不拼命令行 → 路径里有空格、有引号都不用脚本操心
    -- ★ `-a 0` 关掉**角度分类器**（cls）：它会把"扁长的行"（一行 50+ 字符、宽高比 >15:1）
    --   误判成 180°，rec 拿着倒过来的图出 "o -s-- --oi d-a--" 这类乱码。2026-10-28 实测：
    --   同一张 62 字符英文命令，`-a 1` 出乱码、`-a 0` 逐字正确；中文短行两者都对。
    --   代价：真正倒过来的截图不再自动纠正（贴图本身就是正着的，这个代价可接受）。
    args = { "-d", ".", "-1", TOOL.det, "-2", TOOL.cls, "-3", TOOL.rec, "-4", TOOL.key,
             "-i", png, "-t", "4", "-p", "50", "-s", "1024", "-a", "0" },
    ansi = TOOL.ansi,
    timeout_ms = TOOL.timeout_ms,
  }
  if not r then
    return nil, "外部引擎没跑起来：" .. tostring(perr)
  end
  if r.timed_out then
    return nil, string.format("外部引擎超时（%d ms），已被宿主终止", TOOL.timeout_ms)
  end
  if r.code ~= 0 then
    return nil, string.format("外部引擎退出码 %s\n%s",
      tostring(r.code), (r.stderr ~= "" and r.stderr or r.stdout):sub(1, 400))
  end
  local text = parse_lines(r.stdout)
  if text == "" then
    return nil, "外部引擎的输出里没有 textLine 行（它换了输出格式？退出码是 0）"
  end
  return text
end

function run(ctx, params)
  params = params or {}
  -- ★ 图片来源：贴图上下文优先；没有就回落到**剪贴板里的截图**（m30）。
  --   这样"截图 → 按快捷键/脚本页运行 → 结果窗"这条路不用先把图钉成贴图。
  local img = ctx.image
  if img == nil then
    img = ext:clip_image()
  end
  if img == nil then
    return "没有可识别的图：在贴图上右键 → 脚本 → OCR；或者先截图（Win+Shift+S / QQ 截图）让剪贴板里有图，再按快捷键或到脚本页运行。"
  end
  -- 只有外置一跑：没装引擎时这一项根本不会出现在菜单里（`requires` 挡掉了），
  -- 所以走到这里就意味着文件都在——失败只可能是"跑坏了"，那种情况如实报，不粉饰。
  local text, why = ocr_external(img)
  if not text then
    return "识别失败：" .. why
  end
  if text == "" then
    return "没有识别出文字（外置引擎跑通了，但框里没有可读的行）。"
  end
  return present(text, params)
end
