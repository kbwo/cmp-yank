local db = {}
local util = require "cmp_yank.util"
local config = require 'cmp.config'


local maxSize = 10000

local cache = {}

local c = config.get_source_config('yank')
local yank_source_path = (c.yank_source_path or vim.fn.getenv('HOME') .. "/.config/cmp-yank") .. '/yank'

function simple_hash(input)
  local hash = 0
  for i = 1, #input do
    local byte = string.byte(input, i)
    hash = (hash * 31 + byte) % 0x100000000
  end
  return string.format("%08x", hash)
end

local function build_item(content, filepath, regtype, filetype)
  local id = simple_hash(util.join(content, "\n"))

  return {
    id = id,
    content = content,
    path = filepath,
    filetype = filetype,
    regtype = regtype,
  }
end

local function create_file(path)
  local dirname = string.match(path, "(.-)/[^/]-$")
  vim.fn.mkdir(dirname, "p")
  local file_handle = assert(io.open(path, "w"))
  file_handle:close()
end

local function read_file(path)
  local fd = vim.loop.fs_open(path, "r", 438)

  if not fd then
    create_file(path)
    fd = vim.loop.fs_open(path, "r", 438)
  end

  local stat = vim.loop.fs_fstat(fd)

  local data = vim.loop.fs_read(fd, stat.size, 0)

  vim.loop.fs_close(fd)

  return data
end

function db.load()
  local str = read_file(yank_source_path)
  local lines = {}
  local item = nil
  local items = {}
  if cache then
    return cache
  end

  for _, line in ipairs(util.split_by_new_line(str)) do
    if util.start_with(line, "\t") then
      table.insert(lines, string.sub(line, 2))
    else
      if item then
        item.content = lines
        table.insert(items, item)
        lines = {}
      end
      if util.trim_string(line) ~= "" then
        local parts = util.split(line, "|")

        local hash = parts[1]
        local path = parts[2]
        local lnum = parts[3]
        local col = parts[4]
        local regtype = parts[5]
        local filetype = parts[6]
        item = {
          id = hash,
          path = path .. "\t" .. lnum .. "\t" .. col,
          regtype = regtype,
          filetype = filetype,
          content = {}
        }
      end
    end
  end
  cache = items
  return items
end

function db.add(content, regtype, filePath, filetype)
  local item = build_item(content, filePath, regtype, filetype)
  local items = db.load()
  local idx = util.find_index(items, function(o)
    return o.id == item.id
  end)
  if idx ~= -1 then
    return
  end
  table.insert(items, item)
  db.write(items)
end

function db.write(rawItems)
  local lines = {}
  local items = rawItems

  if #items > maxSize then
    items = util.slice_array(items, 1, maxSize)
  end


  for _, item in ipairs(items) do
    local filepath, lnum, col = '', '', ''
    for token in string.gmatch(item["path"], "[^\t]+") do
      if not filepath then
        filepath = token
      elseif not lnum then
        lnum = token
      elseif not col then
        col = token
      end
    end

    local line = item.id .. '|' .. filepath .. '|' .. lnum .. '|' .. col .. "|" .. item.regtype .. "|" .. item.filetype
    table.insert(lines, line)
    for _, s in ipairs(item.content) do
      table.insert(lines, "\t" .. s)
    end
  end

  local filePath = yank_source_path
  local file = vim.loop.fs_open(filePath, "w", 438)

  vim.loop.fs_write(file, util.join(lines, "\n") .. "\n", 1, function(err)
    if err then
      vim.fn.echoerr("Error writing to file:", err)
    end

    -- Close the file when done
    vim.loop.fs_close(file, function(close_err)
      if close_err then
        vim.fn.echoerr("Error closing file:", close_err)
      end
    end)
  end)
  cache = rawItems
end

return db
