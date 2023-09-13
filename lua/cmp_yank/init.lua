local cmp = require("cmp")
local db = require("cmp_yank.db")
local util = require("cmp_yank.util")

local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source.complete(self, request, callback)
  print('called')
  local limit = 3
  local items = db.load()
  ---@type string
  local line = request.context.cursor_before_line
  local input = string.sub(line, request.offset - 1)
  items = util.reverse_table(items)
  items = util.filter_table(items, function(o)
    if o.regtype == "^V" then
      return false
    end
    return o.filetype == vim.bo.filetype and util.start_with(util.trim_string(o.content[1]), input)
  end)

  items = util.slice_array(items, 0, limit)

  local result = util.map_table(items, function(item)
    local ind = util.reduce_table(item.content, function(p, s)
      local leadingWhiteSpace = s:match("^%s*")

      local ms_length = leadingWhiteSpace and #leadingWhiteSpace or 0
      return math.min(ms_length, p)
    end, math.huge)

    local lines = util.map_table(item.content, function(s, i)
      if i == 0 then
        return s:gsub("^%s*", "")
      end
      return s:sub(ind, #s)
    end)
    local insertText = util.join(lines, "\n")
    return {
      insertText,
      label = util.trim_string(item.content[1]),
      kind = cmp.lsp.CompletionItemKind.Snippet,
      documentation = {
        kind = 'markdown',
        value = markdown_block(util.join(lines, '\n'), item.filetype)
      }
    }
  end)

  callback(result)
end

function markdown_block(code, filetype)
  filetype = filetype == 'javascriptreact' and 'javascript' or filetype
  filetype = filetype == 'typescriptreact' and 'typescript' or filetype
  return '``` ' .. filetype .. '\n' .. code .. '\n```'
end

return source
