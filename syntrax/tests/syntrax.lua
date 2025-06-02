local lu = require("luaunit")

local Syntrax = require("syntrax")

local mod = {}

function mod.TestExecuteSimple()
   local rails, err = Syntrax.execute("l r s")
   lu.assertNil(err)
   lu.assertNotNil(rails)
   lu.assertEquals(#rails, 3)
   lu.assertEquals(rails[1].kind, "left")
   lu.assertEquals(rails[2].kind, "right")
   lu.assertEquals(rails[3].kind, "straight")
end

function mod.TestExecuteWithRepetition()
   local rails, err = Syntrax.execute("[l] rep 4")
   lu.assertNil(err)
   lu.assertNotNil(rails)
   lu.assertEquals(#rails, 4)
   for i = 1, 4 do
      lu.assertEquals(rails[i].kind, "left")
   end
end

function mod.TestExecuteEmpty()
   local rails, err = Syntrax.execute("")
   lu.assertNil(err)
   lu.assertNotNil(rails)
   lu.assertEquals(#rails, 0)
end

function mod.TestExecuteError()
   local rails, err = Syntrax.execute("l rep 3")
   lu.assertNil(rails)
   lu.assertNotNil(err)
   lu.assertEquals(err.code, "unexpected_token")
   lu.assertStrContains(err.message, "Unexpected token 'rep'")
end

function mod.TestExecuteInvalidToken()
   local rails, err = Syntrax.execute("x y z")
   lu.assertNil(rails)
   lu.assertNotNil(err)
   lu.assertEquals(err.code, "unexpected_token")
end

function mod.TestVersion()
   lu.assertNotNil(Syntrax.VERSION)
   lu.assertStrContains(Syntrax.VERSION, "dev")
end

function mod.TestRailStructure()
   local rails, err = Syntrax.execute("l r")
   lu.assertNil(err)
   lu.assertEquals(#rails, 2)
   
   -- First rail has no parent
   lu.assertNil(rails[1].parent)
   lu.assertNotNil(rails[1].incoming_direction)
   lu.assertNotNil(rails[1].outgoing_direction)
   
   -- Second rail's parent is the first
   lu.assertEquals(rails[2].parent, 1)
   lu.assertEquals(rails[2].incoming_direction, rails[1].outgoing_direction)
end

return mod