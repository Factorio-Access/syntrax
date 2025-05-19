local lu = require("luaunit")

local tests = {
   { "span", require("syntrax.span") },
   { "lexer", require("syntrax.tests.lexer") },
}

local runner = lu.LuaUnit.new()
os.exit(runner:runSuiteByInstances(tests))
