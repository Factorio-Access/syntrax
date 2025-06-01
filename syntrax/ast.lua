--[[
Abstract Syntax Tree definitions for Syntrax.

The AST represents the structure of a Syntrax program after parsing but before
compilation to VM bytecode. Each node carries span information for error reporting.
]]

local mod = {}

---@enum syntrax.AST_NODE_TYPE
mod.AST_NODE_TYPE = {
   -- Basic rail placement commands
   LEFT = "left",
   RIGHT = "right",
   STRAIGHT = "straight",

   -- Repetition: (body) rep count
   REPETITION = "repetition",

   -- Sequence of commands - implicit grouping, also used at top level
   SEQUENCE = "sequence",
}

---@class syntrax.ast.Node Base class for all AST nodes
---@field type syntrax.AST_NODE_TYPE
---@field span syntrax.Span

---@class syntrax.ast.Left: syntrax.ast.Node

---@class syntrax.ast.Right: syntrax.ast.Node

---@class syntrax.ast.Straight: syntrax.ast.Node

---@class syntrax.ast.Sequence: syntrax.ast.Node
---@field statements syntrax.ast.Node[]

---@class syntrax.ast.Repetition: syntrax.ast.Node
---@field body syntrax.ast.Sequence The statement(s) to repeat
---@field count number How many times to repeat

-- Factory functions for creating AST nodes

---@param span syntrax.Span
---@return syntrax.ast.Left
function mod.left(span)
   return {
      type = mod.AST_NODE_TYPE.LEFT,
      span = span,
   }
end

---@param span syntrax.Span
---@return syntrax.ast.Right
function mod.right(span)
   return {
      type = mod.AST_NODE_TYPE.RIGHT,
      span = span,
   }
end

---@param span syntrax.Span
---@return syntrax.ast.Straight
function mod.straight(span)
   return {
      type = mod.AST_NODE_TYPE.STRAIGHT,
      span = span,
   }
end

---@param statements syntrax.ast.Node[]
---@param span syntrax.Span
---@return syntrax.ast.Sequence
function mod.sequence(statements, span)
   return {
      type = mod.AST_NODE_TYPE.SEQUENCE,
      statements = statements,
      span = span,
   }
end

---@param body syntrax.ast.Sequence
---@param span syntrax.Span
---@return syntrax.ast.Repetition
function mod.repetition(body, span)
   return {
      type = mod.AST_NODE_TYPE.REPETITION,
      body = body,
      span = span,
   }
end

return mod
