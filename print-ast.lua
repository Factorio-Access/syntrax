#!/usr/bin/env lua
-- Pretty-print AST for Syntrax programs

local Parser = require("syntrax.parser")
local Ast = require("syntrax.ast")

-- Get input from command line or stdin
local input
if arg and arg[1] then
   -- Read from file if provided
   local file = io.open(arg[1], "r")
   if not file then
      io.stderr:write("Error: Could not open file '" .. arg[1] .. "'\n")
      os.exit(1)
   end
   input = file:read("*a")
   file:close()
else
   -- Read from stdin
   input = io.read("*a")
end

-- Parse the input
local ast, err = Parser.parse(input)
if err then
   io.stderr:write("Parse error: " .. err.message .. "\n")
   if err.span then
      local l1, c1 = err.span:get_printable_range()
      io.stderr:write(string.format("  at line %d, column %d\n", l1, c1))
   end
   os.exit(1)
end

-- Pretty print the AST
local function indent(level)
   return string.rep("  ", level)
end

local function print_ast(node, level)
   level = level or 0

   if node.type == Ast.NODE_TYPE.SEQUENCE then
      print(indent(level) .. "sequence:")
      if #node.statements == 0 then
         print(indent(level + 1) .. "(empty)")
      else
         for i, stmt in ipairs(node.statements) do
            print(indent(level + 1) .. "- " .. "statement " .. i .. ":")
            print_ast(stmt, level + 2)
         end
      end
   elseif node.type == Ast.NODE_TYPE.LEFT then
      print(indent(level) .. "left")
   elseif node.type == Ast.NODE_TYPE.RIGHT then
      print(indent(level) .. "right")
   elseif node.type == Ast.NODE_TYPE.STRAIGHT then
      print(indent(level) .. "straight")
   elseif node.type == Ast.NODE_TYPE.REPETITION then
      print(indent(level) .. "repetition:")
      print(indent(level + 1) .. "count: " .. (node.count or "(unknown)"))
      print(indent(level + 1) .. "body:")
      print_ast(node.body, level + 2)
   else
      print(indent(level) .. "unknown: " .. tostring(node.type))
   end
end

-- Print the root
print("program:")
print_ast(ast, 1)
