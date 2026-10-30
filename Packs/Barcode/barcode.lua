-- 二维码 / 条形码：用官方随包的 ZXing 工具解码当前贴图（或剪贴板截图），
-- 结果进文本窗。识别到网址可选直接打开；识别到图片字节可用系统默认程序打开。
--
-- ★ 官方工具随包安装，用户不需要自己放 exe。工具源码与构建在仓库 `tools/barcode/`。
-- ★ 二维码是字节容器：网址/文本/WiFi/联系人都是“约定”；二进制图片由文件头判断格式。
--   图片必须能完整解出字节才还原；解不出时只报“二进制”，不把乱码塞进文本框。
-- ★ 网址只允许 http/https，且默认不自动打开；图片只自动打开光栅格式，
--   SVG/可执行文件一律不自动打开（二维码内容不可信）。

name = "条码识别"
category = "picture"
role = "image"
menu = "条码识别"

requires = {
  "./barcode_tool/CurSeenBarcode.exe",
}

local TOOL = {
  exe = "./barcode_tool/CurSeenBarcode.exe",
  timeout_ms = 15000,
}

function schema()
  return {
    {
      key = "open_url",
      label = "直接打开网址",
      type = "bool",
      default = false,
    },
    {
      key = "open_image",
      label = "直接打开图片",
      type = "bool",
      default = true,
    },
    {
      key = "hotkey",
      label = "快捷键",
      type = "hotkey",
    },
  }
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function unquote(s)
  s = trim(s)
  if #s >= 2 and s:sub(1, 1) == '"' and s:sub(-1) == '"' then
    return s:sub(2, -2)
  end
  return s
end

--- 从 `Text:` 与 `Bytes:` 两行取值；`Bytes` 是空格分隔的十六进制。
local function parse_output(out)
  local text, hex, format, content = nil, nil, nil, nil
  for line in out:gmatch("[^\r\n]+") do
    local t = line:match("^Text:%s*(.*)$")
    if t then text = unquote(t) end
    local h = line:match("^Bytes:%s*(.*)$")
    if h then hex = h end
    local f = line:match("^Format:%s*(.*)$")
    if f then format = trim(f) end
    local c = line:match("^Content:%s*(.*)$")
    if c then content = trim(c) end
  end
  return text, hex, format, content
end

local function hex_to_bytes(hex)
  if not hex then return nil end
  local clean = hex:gsub("%s+", "")
  if #clean == 0 or #clean % 2 ~= 0 then return nil end
  local out = {}
  for i = 1, #clean, 2 do
    local n = tonumber(clean:sub(i, i + 1), 16)
    if not n then return nil end
    out[#out + 1] = string.char(n)
  end
  return table.concat(out)
end

local function image_ext(bytes)
  if not bytes then return nil end
  if bytes:sub(1, 8) == "\137PNG\r\n\26\n" then return "png" end
  if bytes:sub(1, 3) == "\255\216\255" then return "jpg" end
  if bytes:sub(1, 6) == "GIF87a" or bytes:sub(1, 6) == "GIF89a" then return "gif" end
  if bytes:sub(1, 2) == "BM" then return "bmp" end
  if bytes:sub(1, 4) == "RIFF" and bytes:sub(9, 12) == "WEBP" then return "webp" end
  if bytes:sub(1, 4) == "II*\0" or bytes:sub(1, 4) == "MM\0*" then return "tif" end
  if bytes:sub(1, 4) == "\0\0\1\0" then return "ico" end
  return nil
end

local function payload_kind(text, content)
  if text and text:match("^[Hh][Tt][Tt][Pp][Ss]?://") then return "网址" end
  if text and text:match("^WIFI:") then return "WiFi" end
  if text and (text:match("^BEGIN:VCARD") or text:match("^MECARD:")) then return "联系人" end
  if text and text:match("^mailto:") then return "邮件" end
  if text and text:match("^tel:") then return "电话" end
  if text and text:match("^sms:") then return "短信" end
  if text and text:match("^geo:") then return "位置" end
  if content and content ~= "" then return content end
  return "文本"
end

local function wifi_lines(text)
  local ssid = text:match("S:([^;]*);")
  local pass = text:match("P:([^;]*);")
  local auth = text:match("T:([^;]*);")
  local lines = {}
  if ssid then lines[#lines + 1] = "- 名称：" .. ssid end
  if pass then lines[#lines + 1] = "- 密码：" .. pass end
  if auth then lines[#lines + 1] = "- 加密：" .. auth end
  return lines
end

local function save_binary(bytes, ext)
  local path = ext:tmpdir() .. "\\barcode_image." .. ext
  local ok, err = ext:write_file(path, bytes)
  if not ok then
    return nil, tostring(err)
  end
  return path
end

function run(ctx, params)
  params = params or {}
  local img = ctx.image
  if img == nil then
    img = ext:clip_image()
  end
  if img == nil then
    return "没有可识别的图：在贴图上右键 → 脚本 → 条码识别；或者先截图让剪贴板里有图。"
  end

  local png = ext:tmpdir() .. "\\barcode_in.png"
  local ok, err = pcall(function() img:save(png) end)
  if not ok then
    return "存临时图片失败：" .. tostring(err)
  end
  local r, perr = ext:proc {
    exe = TOOL.exe,
    args = { "-single", png },
    ansi = false,
    timeout_ms = TOOL.timeout_ms,
  }
  if not r then
    return "条码工具没跑起来：" .. tostring(perr)
  end
  if r.timed_out then
    return "条码工具超时，已被宿主终止。"
  end
  if r.code ~= 0 then
    return string.format("条码工具退出码 %s：\n%s", tostring(r.code), (r.stderr ~= "" and r.stderr or r.stdout):sub(1, 400))
  end

  local text, hex, format, content = parse_output(r.stdout)
  if not format then
    return "没有识别到条码（工具输出里没有 Format 行）。"
  end
  local bytes = hex_to_bytes(hex)
  local ext_name = image_ext(bytes)
  local kind = payload_kind(text, content)
  local out = {
    "格式：" .. format,
    "类型：" .. kind,
  }
  if text and text ~= "" then
    out[#out + 1] = "内容：" .. text
  end
  if kind == "WiFi" and text then
    for _, line in ipairs(wifi_lines(text)) do out[#out + 1] = line end
  end

  if ext_name then
    if params.open_image ~= false and ext.open_temp then
      local path, oerr = ext:open_temp(bytes, ext_name)
      if path then
        out[#out + 1] = "图片：" .. ext_name:upper() .. "，" .. #bytes .. " 字节，已用默认程序打开"
      else
        out[#out + 1] = "图片：" .. ext_name:upper() .. "，" .. #bytes .. " 字节；打开失败：" .. tostring(oerr)
      end
    else
      local path, werr = save_binary(bytes, ext_name)
      if path then
        out[#out + 1] = "图片：" .. ext_name:upper() .. "，" .. #bytes .. " 字节，已保存到 " .. path
      else
        out[#out + 1] = "图片：" .. ext_name:upper() .. "，" .. #bytes .. " 字节；保存失败：" .. tostring(werr)
      end
    end
  elseif bytes and #bytes > 0 and (content == "Binary" or content == "Mixed") then
    local path, werr = save_binary(bytes, "bin")
    if path then
      out[#out + 1] = "二进制：" .. #bytes .. " 字节，已保存到 " .. path .. "（未自动打开）"
    else
      out[#out + 1] = "二进制：" .. #bytes .. " 字节；保存失败：" .. tostring(werr)
    end
  end

  if kind == "网址" and params.open_url == true then
    if ext.open_url then
      local opened, oerr = ext:open_url(text)
      out[#out + 1] = opened and "已打开网址" or ("打开网址失败：" .. tostring(oerr))
    else
      out[#out + 1] = "当前宿主不支持直接打开网址"
    end
  end

  return table.concat(out, "\n")
end
