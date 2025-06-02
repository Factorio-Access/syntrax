local lu = require("luaunit")

local tests = {
   { "span", require("syntrax.span") },
   { "lexer", require("syntrax.tests.lexer") },
   { "ast", require("syntrax.tests.ast") },
   { "parser", require("syntrax.tests.parser") },
   { "directions", require("syntrax.tests.directions") },
   { "vm", require("syntrax.tests.vm") },
   { "compiler", require("syntrax.tests.compiler") },
}

local runner = lu.LuaUnit.new()
os.exit(runner:runSuiteByInstances(tests))
