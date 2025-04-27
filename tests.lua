local lu = require("luaunit")

local tests = {
   { "span", require("syntrax.span") },
}

local runner = lu.LuaUnit.new()
os.exit(runner:runSuiteByInstances(tests))
