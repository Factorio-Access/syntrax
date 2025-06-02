--[[
Virtual Machine for Syntrax language.

Executes bytecode to produce a graph of rail placements.
]]

local Directions = require("syntrax.directions")

local mod = {}

---@enum syntrax.vm.OperandKind
mod.OPERAND_KIND = {
   VALUE = "value",
   REGISTER = "register",
}

---@enum syntrax.vm.ValueType
mod.VALUE_TYPE = {
   NUMBER = "number",
}

---@enum syntrax.vm.BytecodeKind
mod.BYTECODE_KIND = {
   LEFT = "left",
   RIGHT = "right",
   STRAIGHT = "straight",
   JNZ = "jnz",
   MATH = "math",
   CMP = "cmp",
   MOV = "mov",
}

---@enum syntrax.vm.MathOp
mod.MATH_OP = {
   ADD = "+",
   SUB = "-",
   MUL = "*",
   DIV = "/",
}

---@enum syntrax.vm.CmpOp
mod.CMP_OP = {
   LT = "<",
   LE = "<=",
   EQ = "==",
   GE = ">=",
   GT = ">",
   NE = "!=",
}

---@enum syntrax.vm.RailKind
mod.RAIL_KIND = {
   LEFT = "left",
   RIGHT = "right",
   STRAIGHT = "straight",
}

---@class syntrax.vm.Operand
---@field kind syntrax.vm.OperandKind
---@field type syntrax.vm.ValueType? Only present for values
---@field argument number Register index or literal value

---@class syntrax.vm.Bytecode
---@field kind syntrax.vm.BytecodeKind
---@field arguments syntrax.vm.Operand[]

---@class syntrax.vm.Rail
---@field parent number? Index of parent rail (nil for first rail)
---@field kind syntrax.vm.RailKind
---@field incoming_direction number Direction hand was facing when placed
---@field outgoing_direction number Direction hand faces after placement

---@class syntrax.vm.State
---@field registers table<number, syntrax.vm.Operand> Array of registers
---@field bytecode syntrax.vm.Bytecode[] Array of bytecode instructions
---@field rails syntrax.vm.Rail[] Output graph of rails
---@field pc number Program counter
---@field hand_direction number Current hand direction (0-15)
---@field parent_rail number? Index of last placed rail
---@field resolve_operand fun(self: syntrax.vm.State, operand: syntrax.vm.Operand): syntrax.vm.Operand
---@field place_rail fun(self: syntrax.vm.State, kind: syntrax.vm.RailKind)
---@field execute_jnz fun(self: syntrax.vm.State, instr: syntrax.vm.Bytecode)
---@field execute_math fun(self: syntrax.vm.State, instr: syntrax.vm.Bytecode)
---@field execute_cmp fun(self: syntrax.vm.State, instr: syntrax.vm.Bytecode)
---@field execute_mov fun(self: syntrax.vm.State, instr: syntrax.vm.Bytecode)
---@field execute_instruction fun(self: syntrax.vm.State): boolean
---@field run fun(self: syntrax.vm.State): syntrax.vm.Rail[]

local VM = {}
local VM_meta = { __index = VM }

---@return syntrax.vm.State
function mod.new()
   return setmetatable({
      registers = {},
      bytecode = {},
      rails = {},
      pc = 1,
      hand_direction = Directions.NORTH, -- Start facing north
      parent_rail = nil,
   }, VM_meta)
end

-- Helper to create operands
function mod.value(type, value)
   return {
      kind = mod.OPERAND_KIND.VALUE,
      type = type,
      argument = value,
   }
end

function mod.register(index)
   return {
      kind = mod.OPERAND_KIND.REGISTER,
      argument = index,
   }
end

-- Helper to create bytecode
function mod.bytecode(kind, ...)
   return {
      kind = kind,
      arguments = { ... },
   }
end

---@param operand syntrax.vm.Operand
---@return syntrax.vm.Operand
function VM:resolve_operand(operand)
   if operand.kind == mod.OPERAND_KIND.VALUE then
      return operand
   elseif operand.kind == mod.OPERAND_KIND.REGISTER then
      local value = self.registers[operand.argument]
      if not value then
         error(string.format("Register r%d not initialized", operand.argument))
      end
      if value.kind == mod.OPERAND_KIND.REGISTER then
         error("Register contains another register reference")
      end
      return value
   else
      error("Unknown operand kind: " .. tostring(operand.kind))
   end
end

---@param kind syntrax.vm.RailKind
function VM:place_rail(kind)
   local incoming = self.hand_direction
   local outgoing = incoming

   -- Update direction based on rail type
   if kind == mod.RAIL_KIND.LEFT then
      outgoing = Directions.rotate(incoming, -1)
   elseif kind == mod.RAIL_KIND.RIGHT then
      outgoing = Directions.rotate(incoming, 1)
   -- STRAIGHT doesn't change direction
   end

   local rail = {
      parent = self.parent_rail,
      kind = kind,
      incoming_direction = incoming,
      outgoing_direction = outgoing,
   }

   table.insert(self.rails, rail)
   self.parent_rail = #self.rails
   self.hand_direction = outgoing
end

---@param instr syntrax.vm.Bytecode
function VM:execute_jnz(instr)
   local value = self:resolve_operand(instr.arguments[1])
   local offset = self:resolve_operand(instr.arguments[2])

   if value.argument ~= 0 then
      self.pc = self.pc + offset.argument
   else
      self.pc = self.pc + 1
   end
end

---@param instr syntrax.vm.Bytecode
function VM:execute_math(instr)
   local dest = instr.arguments[1]
   if dest.kind ~= mod.OPERAND_KIND.REGISTER then
      error("MATH destination must be a register")
   end

   local left = self:resolve_operand(instr.arguments[2])
   local right = self:resolve_operand(instr.arguments[3])
   local op = instr.arguments[4]

   local result
   if op.argument == mod.MATH_OP.ADD then
      result = left.argument + right.argument
   elseif op.argument == mod.MATH_OP.SUB then
      result = left.argument - right.argument
   elseif op.argument == mod.MATH_OP.MUL then
      result = left.argument * right.argument
   elseif op.argument == mod.MATH_OP.DIV then
      result = left.argument / right.argument
   else
      error("Unknown math operation: " .. tostring(op.argument))
   end

   self.registers[dest.argument] = mod.value(mod.VALUE_TYPE.NUMBER, result)
   self.pc = self.pc + 1
end

---@param instr syntrax.vm.Bytecode
function VM:execute_cmp(instr)
   local dest = instr.arguments[1]
   if dest.kind ~= mod.OPERAND_KIND.REGISTER then
      error("CMP destination must be a register")
   end

   local val1 = self:resolve_operand(instr.arguments[2])
   local val2 = self:resolve_operand(instr.arguments[3])
   local op = instr.arguments[4]

   local result
   if op.argument == mod.CMP_OP.LT then
      result = val1.argument < val2.argument
   elseif op.argument == mod.CMP_OP.LE then
      result = val1.argument <= val2.argument
   elseif op.argument == mod.CMP_OP.EQ then
      result = val1.argument == val2.argument
   elseif op.argument == mod.CMP_OP.GE then
      result = val1.argument >= val2.argument
   elseif op.argument == mod.CMP_OP.GT then
      result = val1.argument > val2.argument
   elseif op.argument == mod.CMP_OP.NE then
      result = val1.argument ~= val2.argument
   else
      error("Unknown comparison operation: " .. tostring(op.argument))
   end

   self.registers[dest.argument] = mod.value(mod.VALUE_TYPE.NUMBER, result and 1 or 0)
   self.pc = self.pc + 1
end

---@param instr syntrax.vm.Bytecode
function VM:execute_mov(instr)
   local dest = instr.arguments[1]
   if dest.kind ~= mod.OPERAND_KIND.REGISTER then
      error("MOV destination must be a register")
   end

   local value = self:resolve_operand(instr.arguments[2])
   self.registers[dest.argument] = value
   self.pc = self.pc + 1
end

---@return boolean True if execution should continue
function VM:execute_instruction()
   if self.pc < 1 or self.pc > #self.bytecode then
      return false -- Program complete
   end

   local instr = self.bytecode[self.pc]

   if instr.kind == mod.BYTECODE_KIND.LEFT then
      self:place_rail(mod.RAIL_KIND.LEFT)
      self.pc = self.pc + 1
   elseif instr.kind == mod.BYTECODE_KIND.RIGHT then
      self:place_rail(mod.RAIL_KIND.RIGHT)
      self.pc = self.pc + 1
   elseif instr.kind == mod.BYTECODE_KIND.STRAIGHT then
      self:place_rail(mod.RAIL_KIND.STRAIGHT)
      self.pc = self.pc + 1
   elseif instr.kind == mod.BYTECODE_KIND.JNZ then
      self:execute_jnz(instr)
   elseif instr.kind == mod.BYTECODE_KIND.MATH then
      self:execute_math(instr)
   elseif instr.kind == mod.BYTECODE_KIND.CMP then
      self:execute_cmp(instr)
   elseif instr.kind == mod.BYTECODE_KIND.MOV then
      self:execute_mov(instr)
   else
      error("Unknown bytecode kind: " .. tostring(instr.kind))
   end

   return true
end

function VM:run()
   while self:execute_instruction() do
      -- Continue execution
   end
   return self.rails
end

-- Pretty printing support
function mod.format_operand(operand)
   if operand.kind == mod.OPERAND_KIND.VALUE then
      return string.format("v(%s)", tostring(operand.argument))
   elseif operand.kind == mod.OPERAND_KIND.REGISTER then
      return string.format("r(%d)", operand.argument)
   else
      return "?"
   end
end

function mod.format_bytecode(bc, index, labels)
   local parts = {}
   
   -- Add label if present
   if labels and labels[index] then
      table.insert(parts, labels[index] .. ":")
   end
   
   -- Add bytecode kind
   table.insert(parts, string.upper(bc.kind))
   
   -- Add arguments
   for i, arg in ipairs(bc.arguments) do
      -- Special handling for operators
      if (bc.kind == mod.BYTECODE_KIND.MATH and i == 4) or
         (bc.kind == mod.BYTECODE_KIND.CMP and i == 4) then
         table.insert(parts, string.format("op(%s)", arg.argument))
      -- Special handling for jump targets
      elseif bc.kind == mod.BYTECODE_KIND.JNZ and i == 2 and arg.kind == mod.OPERAND_KIND.VALUE then
         -- Try to find label for target
         local target = index + arg.argument
         if labels and labels[target] then
            table.insert(parts, labels[target])
         else
            table.insert(parts, mod.format_operand(arg))
         end
      else
         table.insert(parts, mod.format_operand(arg))
      end
   end
   
   return table.concat(parts, " ")
end

-- Re-export direction formatting for convenience
mod.format_direction = Directions.to_name

return mod