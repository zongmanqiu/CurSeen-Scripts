-- 图片体检：一张贴图的**全部信息类读数**，一次跑完、一扇窗看完。
-- 用法：贴图上点右键 → 脚本 → 图片体检。
--
-- 合并说明（2026-10-28 用户口径）：过去这里是五个脚本（图片信息 / 取色板 / 对比度体检 /
-- 清晰度评分 / 图像体检报告），菜单里并排五条、结果还分散在五扇窗。它们的输入都是
-- "当前贴图"、形状都是"算完进文本窗"——合成一条，菜单干净、信息也在一起。
--
-- 每一段的公式都是**写死**的（改之前先看注释里的出处，别凭印象改阈值）：
--   · 比例 = 宽/高的连分数最简比；常见比例只在误差 < 2% 时点名
--   · 主色板 = 中位切分（Median Cut，确定性；不用 K-Means——Lua 侧没有随机源，不可复现）
--   · 对比度 = WCAG 2.1：相对亮度线性化后 (Lmax+0.05)/(Lmin+0.05)；4.5 = AA，7.0 = AAA
--   · 清晰度 = 灰度（0.299R+0.587G+0.114B）上的 **4 邻域**拉普拉斯响应方差
-- 大图一律步长采样（按面积开方，各类各自封顶），输出里写明采样了多少点——
-- "数字看着精确、其实只看了百分之一"是最容易骗人的一种读数。

name = "图片体检"
category = "picture"
role = "image"
menu = "图片体检"

function schema()
  return {
    {
      key = "colors",
      label = "主色板色数",
      type = "choice",
      choices = { "4", "8", "16" },
      labels = { "4 色", "8 色", "16 色" },
      default = "8",
    },
    {
      -- 截图 → 按键 → 体检：没有贴图上下文时用剪贴板里的图（m30）。
      key = "hotkey",
      label = "快捷键",
      type = "hotkey",
    },
  }
end

local MAX_SAMPLES = 200000
local PALETTE_SAMPLES = 20000
local UNIQUE_CAP = 65536
local MAX_PIXELS = 1000000

local function gcd(a, b)
  while b ~= 0 do
    a, b = b, a % b
  end
  return a
end

local STANDARD = {
  { 1, 1 },
  { 4, 3 },
  { 3, 2 },
  { 16, 9 },
  { 16, 10 },
  { 9, 16 },
  { 21, 9 },
}

--- 采样步长：让采样点数量不超过 `cap`。
local function step_for(total, cap)
  if total <= cap then
    return 1
  end
  return math.max(1, math.ceil(math.sqrt(total / cap)))
end

-- ── 1. 尺寸 / 比例 / 朝向 ─────────────────────────────────────────────

local function basic_lines(w, h)
  local g = gcd(w, h)
  local decimal = w / h
  local best, best_err = nil, math.huge
  for _, s in ipairs(STANDARD) do
    local target = s[1] / s[2]
    local err = math.abs(decimal - target) / target * 100
    if err < best_err then
      best, best_err = s, err
    end
  end
  local orientation = "方"
  if w > h then
    orientation = "横"
  elseif h > w then
    orientation = "竖"
  end
  local lines = {}
  lines[#lines + 1] = string.format("- 尺寸：%d × %d（%d 像素，%s向）", w, h, w * h, orientation)
  lines[#lines + 1] = string.format(
    "- 比例：%d:%d = %.3f%s",
    w / g, h / g, decimal,
    (best and best_err < 2.0)
        and string.format("  ≈ %d:%d（差 %.2f%%）", best[1], best[2], best_err)
      or "  （对不上常见比例）"
  )
  return lines
end

-- ── 2. 透明度 / 唯一色 ───────────────────────────────────────────────

local function alpha_lines(img)
  local w, h = img.w, img.h
  local step = step_for(w * h, MAX_SAMPLES)
  local s = img:bytes()
  local opaque, semi, clear, sampled = 0, 0, 0, 0
  local seen, unique, capped = {}, 0, false
  for y = 0, h - 1, step do
    for x = 0, w - 1, step do
      local i = (y * w + x) * 4 + 1
      local r, g, b, a = string.byte(s, i, i + 3)
      sampled = sampled + 1
      if a == 255 then
        opaque = opaque + 1
      elseif a == 0 then
        clear = clear + 1
      else
        semi = semi + 1
      end
      if not capped then
        local key = (r << 16) | (g << 8) | b
        if seen[key] == nil then
          seen[key] = true
          unique = unique + 1
          if unique >= UNIQUE_CAP then
            capped = true
          end
        end
      end
    end
  end
  local lines = {
    string.format("- 不透明：%d", opaque),
    string.format("- 半透明：%d", semi),
    string.format("- 全透明：%d", clear),
    string.format("- 采样：%d 点，步长 %d", sampled, step),
    capped and string.format("- 唯一色：≥ %d（已封顶，不再往上数）", UNIQUE_CAP)
      or string.format("- 唯一色：%d（采样范围内）", unique),
  }
  return lines
end

-- ── 2b. 平均色 / 平均不透明度（只看不透明像素）────────────────────────

local function average_lines(img)
  local w, h = img.w, img.h
  local step = step_for(w * h, 40000)
  local s = img:bytes()
  local sr, sg, sb, sa, n = 0, 0, 0, 0, 0
  for y = 0, h - 1, step do
    for x = 0, w - 1, step do
      local i = (y * w + x) * 4 + 1
      local r, g, b, a = string.byte(s, i, i + 3)
      if a > 0 then
        sr, sg, sb, sa, n = sr + r, sg + g, sb + b, sa + a, n + 1
      end
    end
  end
  if n == 0 then
    return { "- （全透明，统计不了）" }
  end
  return {
    string.format(
      "- 平均色：#%02X%02X%02X（%d 个不透明像素参与，步长 %d）",
      math.floor(sr / n + 0.5), math.floor(sg / n + 0.5), math.floor(sb / n + 0.5), n, step
    ),
    string.format("- 平均不透明度：%.1f%%", sa / n / 255 * 100),
  }
end

-- ── 3. 主色板（中位切分）──────────────────────────────────────────────

local function channel(c, which)
  if which == 0 then
    return (c >> 16) & 0xFF
  elseif which == 1 then
    return (c >> 8) & 0xFF
  end
  return c & 0xFF
end

local function widest_channel(px, lo, hi)
  local rmin, rmax, gmin, gmax, bmin, bmax = 255, 0, 255, 0, 255, 0
  for i = lo, hi do
    local c = px[i]
    local r, g, b = channel(c, 0), channel(c, 1), channel(c, 2)
    if r < rmin then rmin = r end
    if r > rmax then rmax = r end
    if g < gmin then gmin = g end
    if g > gmax then gmax = g end
    if b < bmin then bmin = b end
    if b > bmax then bmax = b end
  end
  local dr, dg, db = rmax - rmin, gmax - gmin, bmax - bmin
  if dr >= dg and dr >= db then
    return dr, 0
  end
  if dg >= db then
    return dg, 1
  end
  return db, 2
end

local function median_cut(px, want)
  local boxes = { { lo = 1, hi = #px } }
  while #boxes < want do
    local best, best_span, best_ch = nil, 0, 0
    for idx, box in ipairs(boxes) do
      if box.hi > box.lo then
        local span, ch = widest_channel(px, box.lo, box.hi)
        if span > best_span then
          best, best_span, best_ch = idx, span, ch
        end
      end
    end
    if best == nil or best_span == 0 then
      break
    end
    local box = boxes[best]
    local slice = {}
    for i = box.lo, box.hi do
      slice[#slice + 1] = px[i]
    end
    table.sort(slice, function(a, b)
      return channel(a, best_ch) < channel(b, best_ch)
    end)
    for i, c in ipairs(slice) do
      px[box.lo + i - 1] = c
    end
    local mid = box.lo + math.floor((box.hi - box.lo) / 2)
    local right = { lo = mid + 1, hi = box.hi }
    box.hi = mid
    boxes[#boxes + 1] = right
  end
  return boxes
end

local function palette_lines(img, want)
  local w, h = img.w, img.h
  local step = step_for(w * h, PALETTE_SAMPLES)
  local s = img:bytes()
  local px = {}
  for y = 0, h - 1, step do
    for x = 0, w - 1, step do
      local i = (y * w + x) * 4 + 1
      local r, g, b, a = string.byte(s, i, i + 3)
      if a > 0 then
        px[#px + 1] = (r << 16) | (g << 8) | b
      end
    end
  end
  local n = #px
  if n == 0 then
    return 0, { "- （全透明，没有不透明像素可取）" }
  end
  local rows = {}
  for _, box in ipairs(median_cut(px, want)) do
    local sr, sg, sb, cnt = 0, 0, 0, box.hi - box.lo + 1
    for i = box.lo, box.hi do
      local c = px[i]
      sr = sr + channel(c, 0)
      sg = sg + channel(c, 1)
      sb = sb + channel(c, 2)
    end
    rows[#rows + 1] = {
      hex = string.format(
        "#%02X%02X%02X",
        math.floor(sr / cnt + 0.5), math.floor(sg / cnt + 0.5), math.floor(sb / cnt + 0.5)
      ),
      share = cnt / n * 100,
    }
  end
  table.sort(rows, function(a, b)
    if a.share ~= b.share then
      return a.share > b.share
    end
    return a.hex < b.hex -- 平票按 HEX 排：同一张图两次跑顺序一致
  end)
  local lines = { string.format("- 采样：%d 点，步长 %d", n, step) }
  for i, c in ipairs(rows) do
    lines[#lines + 1] = string.format("%d. %s — %.1f%%", i, c.hex, c.share)
  end
  return #rows, lines
end

-- ── 4. 对比度（WCAG 2.1）─────────────────────────────────────────────

local function linear(c)
  local v = c / 255
  if v <= 0.03928 then
    return v / 12.92
  end
  return ((v + 0.055) / 1.055) ^ 2.4
end

local function luminance(r, g, b)
  return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
end

local function median(values)
  table.sort(values)
  return values[math.floor((#values + 1) / 2)]
end

--- 四角各 5×5 的中位色投票；**平票取第一个角（左上）**。
--  ★ 不许用 `pairs` 遍历哈希表来择优：Lua 5.4 的字符串哈希带随机种子，遍历顺序每次
--  都可能不同 ⇒ 四个角颜色互不相同时，"背景"会随机换 ⇒ 同一张图两次跑出不同判词。
local function majority_corner(med)
  local best, bestn = med[1], 0
  for i = 1, #med do
    local n = 0
    for j = 1, #med do
      if med[j][1] == med[i][1] and med[j][2] == med[i][2] and med[j][3] == med[i][3] then
        n = n + 1
      end
    end
    if n > bestn then
      best, bestn = med[i], n
    end
  end
  return best
end

local function hex_of(c)
  return string.format("#%02X%02X%02X", c[1], c[2], c[3])
end

local function contrast_lines(img)
  local w, h = img.w, img.h
  local s = img:bytes()
  local corners = {
    { 0, 0 },
    { math.max(0, w - 5), 0 },
    { 0, math.max(0, h - 5) },
    { math.max(0, w - 5), math.max(0, h - 5) },
  }
  local med = {}
  for _, corner in ipairs(corners) do
    local rs, gs, bs = {}, {}, {}
    for dy = 0, 4 do
      for dx = 0, 4 do
        local x, y = corner[1] + dx, corner[2] + dy
        if x < w and y < h then
          local i = (y * w + x) * 4 + 1
          local r, g, b = string.byte(s, i, i + 2)
          rs[#rs + 1], gs[#gs + 1], bs[#bs + 1] = r, g, b
        end
      end
    end
    if #rs > 0 then
      med[#med + 1] = { median(rs), median(gs), median(bs) }
    end
  end
  if #med == 0 then
    return { "- （读不出四角颜色）" }
  end
  local bg = majority_corner(med)
  local bg_key = (bg[1] << 16) | (bg[2] << 8) | bg[3]

  -- 前景 = 采样里出现最多的非背景色
  local step = step_for(w * h, PALETTE_SAMPLES)
  local counts, fg, fg_n, sampled = {}, nil, 0, 0
  for y = 0, h - 1, step do
    for x = 0, w - 1, step do
      local i = (y * w + x) * 4 + 1
      local r, g, b, a = string.byte(s, i, i + 3)
      if a > 0 then
        sampled = sampled + 1
        local key = (r << 16) | (g << 8) | b
        if key ~= bg_key then
          counts[key] = (counts[key] or 0) + 1
          if counts[key] > fg_n then
            fg_n, fg = counts[key], { r, g, b }
          end
        end
      end
    end
  end
  if fg == nil then
    return {
      string.format("- 对比度：整张图都是背景色 %s，没有可比较的前景色", hex_of(bg)),
    }
  end
  local l1, l2 = luminance(fg[1], fg[2], fg[3]), luminance(bg[1], bg[2], bg[3])
  if l1 < l2 then
    l1, l2 = l2, l1
  end
  local ratio = (l1 + 0.05) / (l2 + 0.05)
  local verdict
  if ratio >= 7.0 then
    verdict = "AAA（正文与大号字都过）"
  elseif ratio >= 4.5 then
    verdict = "AA（正文过；AAA 要 7.0）"
  elseif ratio >= 3.0 then
    verdict = "只够 AA-large（大号字 ≥18pt / 粗体 ≥14pt；正文不过）"
  else
    verdict = "不过（连 3.0 都不到，换个色）"
  end
  local share = sampled > 0 and (fg_n / sampled * 100) or 0
  return {
    string.format("- 前景：%s（占采样 %.0f%%）", hex_of(fg), share),
    string.format("- 背景：%s（四角中位色）", hex_of(bg)),
    string.format("- 对比度：%.2f:1 → %s", ratio, verdict),
  }
end

-- ── 5. 清晰度（4 邻域拉普拉斯方差）────────────────────────────────────

local function sharpness_lines(img)
  local w, h = img.w, img.h
  if w < 3 or h < 3 then
    return { "- （图太小，内部像素不够算拉普拉斯）" }
  end
  local step = step_for(w * h, MAX_PIXELS)
  local s = img:bytes()
  local gw = math.ceil(w / step)
  local gh = math.ceil(h / step)
  local g = {}
  for gy = 0, gh - 1 do
    for gx = 0, gw - 1 do
      local i = ((gy * step) * w + gx * step) * 4 + 1
      local r, gg, b = string.byte(s, i, i + 2)
      g[gy * gw + gx] = 0.299 * r + 0.587 * gg + 0.114 * b
    end
  end
  local n, sum, sumsq = 0, 0.0, 0.0
  for y = 1, gh - 2 do
    for x = 1, gw - 2 do
      local i = y * gw + x
      local l = 4 * g[i] - g[i - 1] - g[i + 1] - g[i - gw] - g[i + gw]
      n = n + 1
      sum = sum + l
      sumsq = sumsq + l * l
    end
  end
  if n == 0 then
    return { "- （内部像素是空的，算不出来）" }
  end
  local mean = sum / n
  local variance = sumsq / n - mean * mean
  if variance < 0 then
    variance = 0
  end
  local band = "偏糊（要么真糊，要么图本身大面积纯色）"
  if variance >= 300 then
    band = "偏清晰（边缘多/细节多）"
  elseif variance >= 50 then
    band = "一般"
  end
  return {
    string.format("- 清晰度：%.1f（拉普拉斯方差）→ %s", variance, band),
    string.format(
      "- 采样：内部 %d 点，步长 %d；只作同批图之间的相对比较——绝对阈值随分辨率与缩放漂移",
      n, step
    ),
  }
end

function run(ctx, params)
  -- ★ 图片来源：贴图上下文优先；没有就回落到**剪贴板里的截图**（m30），
  --   于是"截图 → 按热键 / 脚本页运行"也能直接体检。
  local img = ctx.image
  if img == nil then
    img = ext:clip_image()
  end
  if img == nil then
    return "没有可体检的图：在贴图上右键 → 脚本 → 图片体检；或者先截图（Win+Shift+S / QQ 截图）让剪贴板里有图，再按热键或到脚本页运行。"
  end
  params = params or {}
  local w, h = img.w, img.h
  if w == 0 or h == 0 then
    return "这张图是空的（0 像素）。"
  end

  -- 输出是**纯文本 Markdown**（结果窗不渲染，复制出去可直接成稿）：
  -- 组与组之间空一行；字段用 `-`；清单（主色板）用 `1. 2. 3.`。
  local out = {}
  local function section(title, lines)
    if #out > 0 then
      out[#out + 1] = ""
    end
    out[#out + 1] = "## " .. title
    for _, l in ipairs(lines) do
      out[#out + 1] = l
    end
  end
  section("基本信息", basic_lines(w, h))
  section("透明度", alpha_lines(img))
  section("颜色", average_lines(img))
  local palette_count, palette = palette_lines(img, tonumber(params.colors) or 8)
  section(string.format("主色板（%d 色）", palette_count), palette)
  section("对比度", contrast_lines(img))
  section("清晰度", sharpness_lines(img))
  return table.concat(out, "\n")
end
