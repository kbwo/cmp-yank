local M = {}

function M.join(strArray, separator)
  local result = ""
  for i, str in ipairs(strArray) do
    result = result .. str
    if i < #strArray then
      result = result .. separator
    end
  end
  return result
end

function M.slice_array(arr, startIdx, endIdx)
  local result = {}
  local length = #arr

  if startIdx < 0 then
    startIdx = length + startIdx + 1
  end
  if endIdx < 0 then
    endIdx = length + endIdx + 1
  end

  startIdx = math.max(1, math.min(startIdx, length + 1))
  endIdx = math.max(1, math.min(endIdx, length))

  for i = startIdx, endIdx do
    table.insert(result, arr[i])
  end

  return result
end

function M.start_with(inputString, prefix)
  return inputString:sub(1, #prefix) == prefix
end

function M.byte_slice(content, startByte, endByte)
  if startByte < 1 then
    startByte = 1
  end
  if endByte > #content then
    endByte = #content
  end
  return string.sub(content, startByte, endByte)
end

function M.reverse_table(arr)
  local reversed = {}
  for i = #arr, 1, -1 do
    table.insert(reversed, arr[i])
  end
  return reversed
end

function M.filter_table(arr, predicate)
  local filtered = {}
  for _, value in ipairs(arr) do
    if predicate(value) then
      table.insert(filtered, value)
    end
  end

  return filtered
end

function M.map_table(arr, callback)
  local result = {}
  for _, value in ipairs(arr) do
    table.insert(result, callback(value))
  end

  return result
end

function M.trim_string(str)
  return str:gsub("^%s*(.-)%s*$", "%1")
end

function M.trim_first_whitespace(str)
  if M.start_with(str, "\n") then
    return str:sub(2)
  end
  return str
end

function M.reduce_table(arr, callback, initialValue)
  local accumulator = initialValue
  local startIndex = 1

  if initialValue == nil then
    accumulator = arr[1]
    startIndex = 2
  end

  for i = startIndex, #arr do
    accumulator = callback(accumulator, arr[i], i, arr)
  end

  return accumulator
end

function M.find_index(arr, callback)
  for index, value in ipairs(arr) do
    if callback(value, index, arr) then
      return index
    end
  end
  return -1
end

function M.split(input, separtor)
  local parts = {}
  for part in (input .. separtor):gmatch("(.-)" .. separtor) do
    table.insert(parts, part)
  end
  return parts
end

function M.split_by_new_line(input)
  local parts = {}
  for part in (input .. "\n"):gmatch("(.-)\r?\n") do
    table.insert(parts, part)
  end
  return parts
end

function M.log_array(tag, t)
  for _, v in ipairs(t) do
    print(tag, vim.inspect(v))
  end
end

function M.string_slice(input, start, finish)
  local len = #input
  if start < 0 then
    start = len + start + 1
  end

  if finish < 0 then
    finish = len + finish + 1
  end

  if start > len then
    return ""
  end

  if finish > len then
    finish = len
  end

  if start > finish then
    return ""
  end

  return string.sub(input, start, finish)
end

return M
