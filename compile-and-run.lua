#!/usr/bin/env lua
-- Compile and run Syntrax programs

local Parser = require("syntrax.parser")
local Compiler = require("syntrax.compiler")
local Vm = require("syntrax.vm")

-- Get input from command line or stdin
local input
if arg and arg[1] then
   if arg[1] == "-c" and arg[2] then
      -- Direct code from command line
      input = arg[2]
   else
      -- Read from file
      local file = io.open(arg[1], "r")
      if not file then
         io.stderr:write("Error: Could not open file '" .. arg[1] .. "'\n")
         os.exit(1)
      end
      input = file:read("*a")
      file:close()
   end
else
   -- Read from stdin
   input = io.read("*a")
end

-- Parse
print("=== Parsing ===")
local ast, err = Parser.parse(input)
if err then
   io.stderr:write("Parse error: " .. err.message .. "\n")
   if err.span then
      local l1, c1 = err.span:get_printable_range()
      io.stderr:write(string.format("  at line %d, column %d\n", l1, c1))
   end
   os.exit(1)
end
print("Parse successful!")

-- Compile
print("\n=== Compiling ===")
assert(ast, "Parser returned nil AST without error")
local bytecode = Compiler.compile(ast)
print(string.format("Generated %d bytecode instructions", #bytecode))

-- Print bytecode listing
print("\n=== Bytecode ===")
print(Compiler.format_bytecode_listing(bytecode))

-- Execute
print("\n=== Executing ===")
local vm = Vm.new()
vm.bytecode = bytecode
local rails, runtime_err = vm:run()

if runtime_err then
   print("\nRuntime error: " .. runtime_err.message)
   return
end

assert(rails)

-- Print results
print(string.format("\nGenerated %d rails:", #rails))
for i, rail in ipairs(rails) do
   local parent_str = rail.parent and string.format("from rail %d", rail.parent) or "initial"
   print(
      string.format(
         "  Rail %d: %s (%s, direction %s->%s)",
         i,
         rail.kind,
         parent_str,
         Vm.format_direction(rail.incoming_direction),
         Vm.format_direction(rail.outgoing_direction)
      )
   )
end

print(string.format("\nFinal hand direction: %s", Vm.format_direction(vm.hand_direction)))

-- Summary
local turn_count = 0
for _, rail in ipairs(rails) do
   if rail.kind ~= "straight" then turn_count = turn_count + 1 end
end
print(string.format("\nSummary: %d rails (%d straight, %d turns)", #rails, #rails - turn_count, turn_count))
