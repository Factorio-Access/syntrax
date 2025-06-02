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
   print(string.format("Generated %d rails for a complete circle", #rails))
   
   -- Check if we ended up back at north
   local last_direction = rails[#rails].outgoing_direction
   if last_direction == 0 then
      print("Success: Ended facing north again!")
   end
end

print()

-- Example 3: Error handling
print("Example 3: Error handling")
rails, err = Syntrax.execute("invalid code")
if err then
   print("Expected error: " .. err.message)
   print("Error code: " .. err.code)
end