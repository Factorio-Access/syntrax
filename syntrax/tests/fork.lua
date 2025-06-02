-- Tests for fork support (rpush, rpop, reset)

local lu = require("luaunit")
local Syntrax = require("syntrax")
local Errors = require("syntrax.errors")
local Directions = require("syntrax.directions")

TestForkSupport = {}

function TestForkSupport:test_rpush_rpop_basic()
   -- Basic push and pop
   local rails, err = Syntrax.execute("s rpush l l rpop s")
   lu.assertNil(err)
   lu.assertNotNil(rails)
   lu.assertEquals(#rails, 4)
   
   -- First straight
   lu.assertEquals(rails[1].kind, "straight")
   lu.assertNil(rails[1].parent)
   
   -- Two lefts
   lu.assertEquals(rails[2].kind, "left")
   lu.assertEquals(rails[2].parent, 1)
   lu.assertEquals(rails[3].kind, "left")
   lu.assertEquals(rails[3].parent, 2)
   
   -- rpop should restore to after first straight
   lu.assertEquals(rails[4].kind, "straight")
   lu.assertEquals(rails[4].parent, 1) -- Parent is first rail, not third
end

function TestForkSupport:test_reset_basic()
   -- Reset returns to initial position
   local rails, err = Syntrax.execute("l r s reset s s")
   lu.assertNil(err)
   lu.assertNotNil(rails)
   lu.assertEquals(#rails, 5)
   
   -- After reset, parent should be nil (initial position)
   lu.assertNil(rails[4].parent)
   lu.assertEquals(rails[5].parent, 4) -- Second straight connects to first
end

function TestForkSupport:test_reset_with_initial()
   -- Reset with explicit initial rail
   local rails, err = Syntrax.execute_with_initial("l r reset s", 5, Directions.EAST)
   lu.assertNil(err)
   lu.assertNotNil(rails)
   lu.assertEquals(#rails, 3)
   
   -- First two rails
   lu.assertEquals(rails[1].parent, 5)
   lu.assertEquals(rails[2].parent, 1)
   
   -- After reset, should return to rail 5
   lu.assertEquals(rails[3].parent, 5)
   lu.assertEquals(rails[3].incoming_direction, Directions.EAST)
end

function TestForkSupport:test_rpop_empty_stack()
   -- Error when popping empty stack
   local rails, err = Syntrax.execute("rpop")
   lu.assertNil(rails)
   lu.assertNotNil(err)
   lu.assertEquals(err.code, Errors.ERROR_CODE.RUNTIME_ERROR)
   lu.assertStrContains(err.message, "empty")
end

function TestForkSupport:test_nested_rpush_rpop()
   -- Nested push/pop operations
   local rails, err = Syntrax.execute("rpush s rpush l rpop s rpop")
   lu.assertNil(err)
   lu.assertNotNil(rails)
   lu.assertEquals(#rails, 3)
   
   -- All rails should connect properly
   lu.assertNil(rails[1].parent)
   lu.assertEquals(rails[2].parent, 1)
   lu.assertEquals(rails[3].parent, 1)
end

function TestForkSupport:test_loop_with_rpush_rpop()
   -- Loops can have mismatched rpush/rpop
   local rails, err = Syntrax.execute("rpush [s rpop rpush] rep 3")
   lu.assertNil(err)
   lu.assertNotNil(rails)
   lu.assertEquals(#rails, 3)
   
   -- All straights should have same parent (initial position)
   lu.assertNil(rails[1].parent)
   lu.assertNil(rails[2].parent) 
   lu.assertNil(rails[3].parent)
end

function TestForkSupport:test_direction_preservation()
   -- rpush/rpop should preserve direction
   local rails, err = Syntrax.execute_with_initial("l l rpush r r rpop s", 1, Directions.NORTH)
   lu.assertNil(err)
   lu.assertNotNil(rails)
   
   -- After two lefts, direction should be NNW (14)
   lu.assertEquals(rails[2].outgoing_direction, 14)
   
   -- After rpop, direction should be restored to NNW
   lu.assertEquals(rails[5].incoming_direction, 14)
   lu.assertEquals(rails[5].outgoing_direction, 14) -- Straight doesn't change direction
end

function TestForkSupport:test_three_way_fork()
   -- Example from spec
   local code = [[
rpush
l r s reset
s s s reset
r s l
]]
   local rails, err = Syntrax.execute_with_initial(code, 1, Directions.EAST)
   lu.assertNil(err)
   lu.assertNotNil(rails)
   lu.assertEquals(#rails, 9)
   
   -- All three branches should start from rail 1
   lu.assertEquals(rails[1].parent, 1) -- First branch
   lu.assertEquals(rails[4].parent, 1) -- Second branch
   lu.assertEquals(rails[7].parent, 1) -- Third branch
end

function TestForkSupport:test_initial_rail_rpush()
   -- Can rpush the initial rail
   local rails, err = Syntrax.execute_with_initial("rpush s s rpop", 10, Directions.SOUTH)
   lu.assertNil(err)
   lu.assertNotNil(rails)
   lu.assertEquals(#rails, 2)
   
   -- Both rails placed from initial position
   lu.assertEquals(rails[1].parent, 10)
   lu.assertEquals(rails[2].parent, 1)
   
   -- After rpop, we're back at initial rail 10
   -- (No rail placed by rpop itself)
end

return TestForkSupport