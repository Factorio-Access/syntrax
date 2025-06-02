#!/usr/bin/env lua
-- Test fork support with rpush, rpop, reset

local Syntrax = require("syntrax")
local Directions = require("syntrax.directions")

-- Test 1: Basic rpush/rpop
print("Test 1: Basic rpush/rpop")
local rails, err = Syntrax.execute("s rpush l l rpop s")
if err then
   print("Error: " .. err.message)
   if err.span then
      local l1, c1 = err.span:get_printable_range()
      print(string.format("  at line %d, column %d", l1, c1))
   end
else
   print(string.format("Success: Generated %d rails", #rails))
   for i, rail in ipairs(rails) do
      print(string.format("  Rail %d: %s", i, rail.kind))
   end
end

print()

-- Test 2: Reset functionality
print("Test 2: Reset functionality")
rails, err = Syntrax.execute_with_initial("l r s reset s s s reset r s l", 1, Directions.EAST)
if err then
   print("Error: " .. err.message)
else
   print(string.format("Success: Generated %d rails", #rails))
end

print()

-- Test 3: Error - rpop on empty stack
print("Test 3: Error - rpop on empty stack")
rails, err = Syntrax.execute("rpop")
if err then
   print("Expected error: " .. err.message)
   if err.span then
      local l1, c1 = err.span:get_printable_range()
      print(string.format("  at line %d, column %d", l1, c1))
   end
else
   print("Unexpected success!")
end

print()

-- Test 4: 3-way split example from spec
print("Test 4: 3-way split example")
local code = [[
rpush
l r s reset
s s s reset
r s l
]]
rails, err = Syntrax.execute_with_initial(code, 1, Directions.EAST)
if err then
   print("Error: " .. err.message)
else
   print(string.format("Success: Generated %d rails", #rails))
end

print()

-- Test 5: Loop with mismatched rpush/rpop
print("Test 5: Loop with mismatched rpush/rpop")
rails, err = Syntrax.execute("s s rpush [ rpop rpush l l s s rpop s s s rpush ] rep 3")
if err then
   print("Error: " .. err.message)
else
   print(string.format("Success: Generated %d rails", #rails))
end

print()

-- Test 6: Initial rail behavior
print("Test 6: Initial rail behavior")
rails, err = Syntrax.execute_with_initial("rpush s s rpop", 5, Directions.NORTH)
if err then
   print("Error: " .. err.message)
else
   print(string.format("Success: Generated %d rails", #rails))
   -- Verify we can rpush the initial rail
   if #rails == 2 then
      print("  Correctly pushed and popped initial rail")
   end
end