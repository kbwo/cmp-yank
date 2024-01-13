require 'cmp'.register_source('yank', require 'cmp_yank'.new())

local db = require "cmp_yank.db"
local util = require "cmp_yank.util"

function handleYankPost()
  -- event can be like
  -- {
  --   inclusive = true,
  --   operator = "y",
  --   regcontents = { 'vim.api.nvim_create_autocmd({ "TextYankPost" }, {' },
  --   regname = "",
  --   regtype = "V",
  --   visual = false
  -- }
  local event = vim.v.event
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.fn.win_getid()
  local regtype = event['regtype']
  local operator = event['operator']
  local regcontents = event['regcontents']
  local regname = event['regname']
  local inclusive = event['inclusive']
  local byteLength = #regcontents
  local maxLength = vim.g.yank_max_length
  maxLength = maxLength and maxLength or nil
  if maxLength and byteLength > maxLength then
    return
  end
  local lnum, col

  if regname == "*" and not inclusive then
    local pos1 = vim.fn.getpos('>')
    local pos2 = vim.fn.getpos('<')
    local lnum1 = pos1[1]
    local col1 = pos1[2]
    local lnum2 = pos2[1]
    local col2 = pos2[2]
    lnum = lnum1

    if col1 <= col2 then
      col = col1
    else
      col = col2
    end
  else
    local pos = vim.fn.getpos('.')
    lnum = pos[1]
    col = pos[2]
  end

  local character = string.len(util.byte_slice(vim.fn.getline(lnum - 1), 0, col))
  if operator == "y" then
    local ranges = {}
    -- block selection
    if util.start_with(regtype, "\x16") then
      local view = vim.fn.winsaveview()
      vim.fn.setpos(".", { 0, lnum, col, 0 })
      for i = lnum + 1, #regcontents do
        local linePos = vim.fn.getline(i - 1)
        local startCharacter = string.len(util.byte_slice(linePos, 0, col - 1))
        local endCharacter = startCharacter + string.len(regcontents[i - lnum])
        local startPos = { line = i - 1, character = startCharacter }
        local endPos = { line = i - 1, character = endCharacter }
        local range = { startPos = startPos, endPos = endPos }
        ranges[#ranges + 1] = range
        vim.cmd("normal! j")
      end
      vim.fn.winrestview(view)
    elseif regtype == "v" then
      local startPos = { line = lnum - 1, character = character }
      local endCharacter = #regcontents == 1 and character + #regcontents[1] - 1 or
          string.len(regcontents[#regcontents - 1])
      local endPos = { line = lnum + #regcontents - 2, character = endCharacter }
      local range = { startPos = startPos, endPos = endPos }
      ranges[#ranges + 1] = range
    elseif regtype == "V" then
      for i = lnum, lnum + #regcontents - 1 do
        local line = vim.fn.getline(i - 1)
        ranges[#ranges + 1] = {
          startPos = { line = i - 1, character = 0 },
          endPos = { line = i - 1, character = string.len(line) }
        }
      end
    else
      vim.fn.echoerr("Unknown regtype: " .. regtype)
    end
  end
  local content = util.join(regcontents, "\n")
  local path = vim.fn.expand('%:p') .. "\t" .. lnum .. "\t" .. col
  regtype = util.start_with(regtype, '\x16') and '^v' or regtype
  db.add(regcontents, regtype, path, vim.bo.filetype)
end

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = handleYankPost
})
