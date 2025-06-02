--[[
Syntrax - Main public interface

This is the primary entry point for the Syntrax library.
All other modules are considered internal implementation details.
]]

local Parser = require("syntrax.parser")
local Compiler = require("syntrax.compiler")
local Vm = require("syntrax.vm")

local mod = {}

-- Version information
mod.VERSION = "0.1.0-dev"

---Execute Syntrax source code and return rail placements
---@param source string The Syntrax source code
---@return Rail[]? rails Array of rail placements, or nil on error
---@return syntrax.Error? error Error object if compilation failed
function mod.execute(source)
   -- Parse
   local ast, parse_err = Parser.parse(source)
   if parse_err then
      return nil, parse_err
   end
   
   -- Parser should always return an AST on success
   assert(ast, "Parser returned nil without error")
   
   -- Compile
   local bytecode = Compiler.compile(ast)
   
   -- Execute
   local vm = Vm.new()
   vm.bytecode = bytecode
   local rails = vm:run()
   
   return rails, nil
end

-- Document the rail structure for API consumers
-- (using different class name to avoid conflicts with internal vm.Rail)
---@class Rail
---@field parent number? Index of parent rail (nil for first rail)
---@field kind string "left", "right", or "straight"
---@field incoming_direction number Direction hand was facing when placed (0-15)
---@field outgoing_direction number Direction hand faces after placement (0-15)

-- Document the error structure for API consumers
-- (actual class defined in errors.lua)

return mod