local lu = require("luaunit")
local serpent = require("serpent")

local AST = require("syntrax.ast")
local Span = require("syntrax.span")

local mod = {}

-- Helper to create dummy spans for testing
local function test_span(text)
   return Span.new(text or "test", 1, 1)
end

function mod.TestBasicNodes()
   -- Test creating basic direction nodes
   local left = AST.left(test_span("l"))
   lu.assertEquals(left.type, AST.AST_NODE_TYPE.LEFT)
   lu.assertNotNil(left.span)

   local right = AST.right(test_span("r"))
   lu.assertEquals(right.type, AST.AST_NODE_TYPE.RIGHT)
   lu.assertNotNil(right.span)

   local straight = AST.straight(test_span("s"))
   lu.assertEquals(straight.type, AST.AST_NODE_TYPE.STRAIGHT)
   lu.assertNotNil(straight.span)
end

function mod.TestSequenceNode()
   local s1 = AST.left(test_span("l"))
   local s2 = AST.right(test_span("r"))
   local s3 = AST.straight(test_span("s"))

   local seq = AST.sequence({ s1, s2, s3 }, test_span("l r s"))
   lu.assertEquals(seq.type, AST.AST_NODE_TYPE.SEQUENCE)
   lu.assertEquals(#seq.statements, 3)
   lu.assertEquals(seq.statements[1].type, AST.AST_NODE_TYPE.LEFT)
   lu.assertEquals(seq.statements[2].type, AST.AST_NODE_TYPE.RIGHT)
   lu.assertEquals(seq.statements[3].type, AST.AST_NODE_TYPE.STRAIGHT)
end

function mod.TestRepetitionNode()
   local body = AST.sequence({
      AST.left(test_span("l")),
      AST.straight(test_span("s")),
   }, test_span("l s"))

   local rep = AST.repetition(body, test_span("(l s) rep 5"))
   lu.assertEquals(rep.type, AST.AST_NODE_TYPE.REPETITION)
   lu.assertEquals(#rep.body.statements, 2)
   lu.assertEquals(rep.body.type, AST.AST_NODE_TYPE.SEQUENCE)
end

function mod.TestComplexAST()
   -- Test representing: l l s (r r s) rep 4 s
   local ast = AST.sequence({
      AST.left(test_span("l")),
      AST.left(test_span("l")),
      AST.straight(test_span("s")),
      AST.repetition(
         AST.sequence({
            AST.right(test_span("r")),
            AST.right(test_span("r")),
            AST.straight(test_span("s")),
         }, test_span("r r s")),
         test_span("(r r s) rep 4")
      ),
      AST.straight(test_span("s")),
   }, test_span("l l s (r r s) rep 4 s"))

   lu.assertEquals(ast.type, AST.AST_NODE_TYPE.SEQUENCE)
   lu.assertEquals(#ast.statements, 5)

   -- Check the repetition node
   ---@type syntrax.ast.Repetition
   local rep = ast.statements[4] --[[@as syntrax.ast.Repetition]]
   lu.assertEquals(rep.type, AST.AST_NODE_TYPE.REPETITION)
   lu.assertEquals(rep.body.type, AST.AST_NODE_TYPE.SEQUENCE)
   lu.assertEquals(#rep.body.statements, 3)
end

return mod
