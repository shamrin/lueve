local Pkg = {}
local std = _G
local ipairs = ipairs
local pairs = pairs
local type = type
local setmetatable = setmetatable
local getmetatable = getmetatable
local tostring = tostring
local print = print
local table = table
local io = io
local string = string
local math = math

setfenv(1, Pkg)

local empty = {}

function printTable(obj, indent, maxDepth, seen)
   seen = seen or {}
   maxDepth = maxDepth or 10
   if seen[obj] then
      io.write("<<cycle detected>>")
      return
   end
   if maxDepth == 0 then
      io.write("<<maxDepth exceeded>>")
      return
   end
   seen[obj] = true
   local indent = indent or 0
   local padding = string.rep("  ", indent)
   io.write("{\n")
   for k, v in pairs(obj) do
      io.write(padding, "  ", tostring(k), ": ")
      if type(v) == "table" then
         printTable(v, indent + 1, maxDepth - 1, seen)
         io.write(",\n")
      else
         io.write(tostring(v), "\n")
      end
   end

   io.write(padding, "}")
   if indent == 0 then
      io.write("\n")
   end
end

function printList(obj)
   io.write("{ ")
   for k, v in ipairs(obj) do
      io.write(tostring(v), ", ")
   end
   io.write("}")
end

if ... == nil then
end

function shallowCopy(obj)
   if type(obj) ~= "table" then return obj end
   local meta = getmetatable(obj)
   local neue = {}
   for k, v in pairs(obj) do
      neue[k] = v
   end
   setmetatable(neue, meta)
   return neue
end

function walk(obj, fn, seen)
   if type(obj) ~= "table" then return end
   seen = seen or {}

   for k, v in pairs(obj) do
      fn(k, v, obj)
      if type(v) == "table" and not seen[v] then
         seen[v] = true
         walk(v, fn, seen)
      end
   end
end

------------------------------------------------------------
-- ID helpers
------------------------------------------------------------

local id = 0
function generateId()
  id = id + 1
  return id
end

------------------------------------------------------------
-- JSON helpers
------------------------------------------------------------

local function isArray(t)
  local i = 0
  for _ in pairs(t) do
      i = i + 1
      if t[i] == nil then return false end
  end
  return true
end

function toJSON(obj, seen)
  seen = seen or {}
  local objType = type(obj)
  if objType == "table" and obj.toJSON then
    return obj:toJSON(seen)
  elseif objType == "table" and isArray(obj) then
    seen[obj] = true
    local temp = {}
    for ix, child in ipairs(obj) do
      if not seen[child] then
        temp[#temp + 1] = toJSON(child, shallowCopy(seen))
      end
    end
    return string.format("[%s]", table.concat(temp, ", "))
  elseif objType == "table" then
    seen[obj] = true
    local temp = {}
    for key, value in pairs(obj) do
      if not seen[value] then
        temp[#temp + 1] = string.format("\"%s\": %s", key, toJSON(value, shallowCopy(seen)))
      end
    end
    return string.format("{%s}", table.concat(temp, ", "))
  elseif objType == "string" then
    return string.format("\"%s\"", obj:gsub("\"", "\\\""):gsub("\n", "\\n"))
  elseif objType == "number" then
    return tostring(obj)
  elseif objType == "boolean" then
    return tostring(obj)
  end
  return "uh oh"
end

------------------------------------------------------------
-- String helpers
------------------------------------------------------------

function makeWhitespace(size, char)
  local whitespace = {}
  local char = char or " "
  for i = 0, size do
    whitespace[#whitespace + 1] = char
  end
  return table.concat(whitespace)
end

function split(str, delim)
  local final = {}
  local index = 1
  local splitStart, splitEnd = string.find(str, delim, index)
  while splitStart do
    final[#final + 1] = string.sub(str, index, splitStart-1)
    index = splitEnd + 1
    splitStart, splitEnd = string.find(str, delim, index)
  end
  final[#final + 1] = string.sub(str, index)
  return final
end

function dedent(str)
    local lines = split(str,'\n')
    local _, indent = lines[1]:find("^%s*")
    local final = {}
    for _, line in ipairs(lines) do
      final[#final + 1] = line:sub(indent + 1)
      final[#final + 1] = "\n"
    end
    return table.concat(final)
end

function indent(str, by)
    local lines = split(str,'\n')
    local whitespace = makeWhitespace(by)
    local final = {}
    for _, line in ipairs(lines) do
      final[#final + 1] = whitespace
      final[#final + 1] = line
      final[#final + 1] = "\n"
    end
    return table.concat(final)
end

function indentString(indent, str)
   local sep = "\n" .. string.rep("  ", indent)
   local result = ""
   for line in string.gmatch(str, "[^\n]+") do
      result = result .. (#result > 0 and sep or "") .. line
   end

   return result
end

function fixPad(str)
  local indent = 0
  for ix=1,#str do
    if str[ix] ~= " " then
      indent = ix - 1
      break
    end
  end
  local sep = "\n"
  local result = ""
  for line in string.gmatch(str, "[^\n]+") do
    result = result .. (#result > 0 and sep or "") .. string.sub(line, indent)
  end

  return result
end

-- Courtesy of <https://gist.github.com/Badgerati/3261142>
-- Returns the Levenshtein distance between the two given strings
function levenshtein(str1, str2)
  local len1 = string.len(str1)
  local len2 = string.len(str2)
  local matrix = {}
  local cost = 0

  -- quick cut-offs to save time
  if (len1 == 0) then
    return len2
  elseif (len2 == 0) then
    return len1
  elseif (str1 == str2) then
    return 0
  end

  -- initialise the base matrix values
  for i = 0, len1, 1 do
    matrix[i] = {}
    matrix[i][0] = i
  end
  for j = 0, len2, 1 do
    matrix[0][j] = j
  end

  -- actual Levenshtein algorithm
  for i = 1, len1, 1 do
    for j = 1, len2, 1 do
      if (str1:byte(i) == str2:byte(j)) then
        cost = 0
      else
        cost = 1
      end

      matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
    end
  end

  -- return the last value - this is the Levenshtein distance
  return matrix[len1][len2]
end

------------------------------------------------------------
-- Package
------------------------------------------------------------

return Pkg

--[[
   print("Testing Set (empty)")
   printTable(Set:new())
   print("Testing Set (content)")
   local testSet = Set:new{"foo", "bar", "baz", "quux"}
   print(testSet)
   print("Testing Set (cardinality)")
   print(#testSet)

   local otherSet = Set:new{"arg", "foo", 6, "baz", true}
   print("Set union with", otherSet)
   print(testSet + otherSet)

   print("Set intersection with", otherSet)
   print(testSet * otherSet)

   print("mutating union")
   local unionedSet = testSet:clone():union(otherSet, true)
   print(unionedSet)

   print("mutating intersect")
   local intersectedSet = testSet:clone():intersection(otherSet, true)
   print(intersectedSet)

   print("add 27 to ", testSet)
   testSet:add(27)
   print(testSet, #testSet)
   print("add 27 again")
   testSet:add(27)
   print(testSet, #testSet)

   print("remove foo")
   testSet:remove("foo")
   print(testSet, #testSet)
   print("remove foo again")
   testSet:remove("foo")
   print(testSet, #testSet)
 ]]--
