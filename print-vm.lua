#!/usr/bin/env lua
-- Demo script to show VM execution

local Vm = require("syntrax.vm")

-- Helper functions
local function bc(...)
   return Vm.bytecode(...)
end

local function val(n)
   return Vm.value(Vm.VALUE_TYPE.NUMBER, n)
end

local function reg(n)
   return Vm.register(n)
end

-- Create a simple program that draws a square
print("Creating bytecode for a square...")
local vm = Vm.new()

vm.bytecode = {
   -- r1 = 4 (number of sides)
   bc(Vm.BYTECODE_KIND.MOV, reg(1), val(4)),
   
   -- loop: draw one side
   bc(Vm.BYTECODE_KIND.STRAIGHT),
   bc(Vm.BYTECODE_KIND.STRAIGHT),
   bc(Vm.BYTECODE_KIND.STRAIGHT),
   bc(Vm.BYTECODE_KIND.STRAIGHT),
   
   -- Turn right (90 degrees = 4 units)
   bc(Vm.BYTECODE_KIND.RIGHT),
   bc(Vm.BYTECODE_KIND.RIGHT),
   bc(Vm.BYTECODE_KIND.RIGHT),
   bc(Vm.BYTECODE_KIND.RIGHT),
   
   -- r1 = r1 - 1
   bc(Vm.BYTECODE_KIND.MATH, reg(1), reg(1), val(1), Vm.math_op(Vm.MATH_OP.SUB)),
   
   -- If r1 != 0, jump back to start of loop (offset -9)
   bc(Vm.BYTECODE_KIND.JNZ, reg(1), val(-9)),
}

-- Print the bytecode
print("\nBytecode listing:")
local labels = {
   [2] = "loop",
   [11] = "end",
}

for i, instr in ipairs(vm.bytecode) do
   print(string.format("%2d: %s", i, Vm.format_bytecode(instr, i, labels)))
end

-- Execute the program
print("\nExecuting...")
local rails = vm:run()

-- Print the output
print(string.format("\nGenerated %d rails:", #rails))
for i, rail in ipairs(rails) do
   local parent_str = rail.parent and string.format("from rail %d", rail.parent) or "initial"
   print(string.format(
      "  Rail %d: %s (%s, direction %s->%s)",
      i,
      rail.kind,
      parent_str,
      Vm.format_direction(rail.incoming_direction),
      Vm.format_direction(rail.outgoing_direction)
   ))
end

print(string.format("\nFinal hand direction: %s", Vm.format_direction(vm.hand_direction)))
print(string.format("Final PC: %d", vm.pc))