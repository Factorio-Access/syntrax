#!/usr/bin/env lua
-- Example of using Syntrax as a library

local Syntrax = require("syntrax")

-- Example 1: Simple rail sequence
print("Example 1: Simple sequence")
local rails, err = Syntrax.execute("l r s")
if err then
   print("Error: " .. err.message)
else
   print(string.format("Generated %d rails", #rails))
end

print()

-- Example 2: Circle pattern
print("Example 2: Circle with repetition")
rails, err = Syntrax.execute("[l l s] rep 8")
if err then
   print("Error: " .. err.message)
else
   assert(rails)
   print(string.format("Generated %d rails for a complete circle", #rails))
   
   -- Check if we ended up back at north
   if #rails > 0 then
      local last_direction = rails[#rails].outgoing_direction
      if last_direction == 0 then
         print("Success: Ended facing north again!")
      end
   end
end

print()

-- Example 3: Fork support with initial rail
print("Example 3: Fork with initial rail")
local Directions = require("syntrax.directions")
rails, err = Syntrax.execute("rpush l r s reset s s", 10, Directions.EAST)
if err then
   print("Error: " .. err.message)
else
   assert(rails)
   print(string.format("Generated %d rails from initial rail 10", #rails))
   -- First rail should connect to rail 10
   if #rails > 0 then
      print(string.format("First rail parent: %s", rails[1].parent or "nil"))
   end
end

print()

-- Example 4: Runtime error handling
print("Example 4: Runtime error handling")
rails, err = Syntrax.execute("s s rpop") -- Error: empty stack
if err then
   print("Expected runtime error: " .. err.message)
   print("Error code: " .. err.code)
   if err.span then
      local line, col = err.span:get_printable_range()
      print(string.format("At line %d, column %d", line, col))
   end
end

print()

-- Example 5: Error handling for parse errors
print("Example 5: Parse error handling")
rails, err = Syntrax.execute("invalid code")
if err then
   print("Expected error: " .. err.message)
   print("Error code: " .. err.code)
end