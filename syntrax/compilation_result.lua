--[[
The outcome of compiling some Syntrax.

This does two things: holds the final result and communicates errors.  `run_if_continuing` will call a closure if there
has not yet been an error or result.  Then one can `:add_error` etc. to put errors into it or `set_result` etc.
]]

local mod = {}

---@class syntrax.CompilationResult
---@field error syntrax.Error?
---@field result any?
local CompilationResult = {}
mod.CompilationResult = CompilationResult
local CompilationResult_meta = { __index = CompilationResult }
mod.new = CompilationResult.new

---@return syntrax.CompilationResult
function CompilationResult.new()
   return setmetatable({
      state = mod.COMPILATION_STATE.ONGOING,
   }, CompilationResult_meta)
end

--- Call the closure if compilation can continue.  This is reentrant.
---@param closure fun()
---@return boolean, any? True if we can continue compiling and then the result of the closure, otherwise false.
function CompilationResult:run_if_continuing(closure)
   if not self.result and not self.error then
      return true, closure()
   else
      return false, nil
   end
end

---@param error syntrax.Error
---@return syntrax.CompilationResult
function CompilationResult:add_error(error)
   self.error = error
   return self
end

---@return any?
function CompilationResult:get_result()
   if self.error then return nil end
   return self.result
end
return mod
