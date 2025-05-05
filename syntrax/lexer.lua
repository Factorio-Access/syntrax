--[[
The lexer.

This is fun because of Lua string processing.  So...

# Overview

We borrow Rust's idea of a token tree.  A token tree is:

- A single token, "l", "foo", "asdfasdf"; or
- A list of tokens surrounded by brackets `( t1, t2, t3 )`.

This means that everything after gets a pre-balanced set of brackets and parsing proceeds recursively: any tree which
isn't a single token has its inner contents partsed, and then moving outward.

A token in our nomenclature is one of the following:

- An identifier: must start with a letter, then at least 1 letter, number, or underscore.  Keywords are identifiers for
  this step.
- A chord: lsl;rsr etc. Like an identifier, but with ; allowed in it.
- A literal: for now only integers.
- A single non-punctuation non-bracket character
- Some bracketed tokens, using (, [, or {.

The next phase in the pipeline figures out if the stuff here is meaningful.
]]
local lu = require("luaunit")
local serpent = require("serpent")

local Span = require("syntrax.span")

local mod = {}

-- For the function below, to split a string up into tokens.
--
-- Order matters. The tuples are { pattern, include_as_token }.
local MUNCHERS = {
   -- Whitepace.
   { "^%s+", false },

   -- A comment, which happens to be at the end of the file.
   { "^%-%-[^\n]*$", false },

   -- A comment not at the end of the file.
   { "^%-%-[^\n]*\n", false },

   -- (possible) identifiers: a set of letters, numbers, _, or ;. Also (possible) numbers: an identifier that happens to
   -- be all digits.
   { "^[%w%d;_]+", true },

   -- Anything else goes to a token by itself.  This includes single-letter identifiers, since the caller cannot know
   -- which way we went.
   { "^.", true },
}

--[[
Infallible function which splits a string at *possible* tokens.

Lua string processing is weird and slow. What we do is split at possible token boundaries and then match them.  It's
possible to do this with patterns instead of substrings etc.  This function never fails (at worst it returns the whole
input string).  After it, one has the list of possible tokens but not yet converted into something meaningful (e.g. not
yet checked for brackets).

This works by matching a set of patterns, taking the closest result toward the beginning, and then moving forward.
qAfterword, we convert that to substrings.

The returned tokens may not be valid, but the string is split such that if they are, it's one token each.

The above patterns match anything. That's the magic of this: we either get one of the tricky subsets, or a single
character, but we always hit at least one.
]]
---@return { text: string, span: syntrax.Span }[]
local function split_at_possibles(text)
   local tokens = {}
   local pos = 1
   local len = #text

   while pos <= len do
      local part, keep

      for i = 1, #MUNCHERS do
         local pat, k = MUNCHERS[i][1], MUNCHERS[i][2]
         local m = string.match(text, pat, pos)
         if m then
            part = m
            keep = k
            break
         end
      end

      assert(part)
      if keep then
         local start = pos
         local stop = pos + #part - 1
         local span = Span.new(text, start, stop)
         table.insert(tokens, { text = part, span = span })
         pos = stop + 1
      else
         -- Doingf it this way means not taking the length twice.
         pos = pos + #part
      end
   end

   return tokens
end

local function strip_tokens_for_test(toks)
   local out = {}
   for i = 1, #toks do
      table.insert(out, toks[i].text)
   end

   return out
end

-- For tests we will drop the spans and check the tokens. We can do spans later.
function mod.TestSplittingPossibles()
   local function check(text, expected_toks)
      local tok = strip_tokens_for_test(split_at_possibles(text))
      lu.assertEquals(tok, expected_toks)
   end

   -- Some sequences of ascii come out right...
   check("abc def ghi", { "abc", "def", "ghi" })
   -- Comments are ignored.
   check(
      [[abc
def -- a comment
ghi -- a comment at the end of the file]],
      { "abc", "def", "ghi" }
   )

   -- ; works
   check("abc;def ghi", { "abc;def", "ghi" })

   -- We break at punctuation.
   check("a$b cde", { "a", "$", "b", "cde" })

   -- weird whitespace is fine
   check(
      [[abc
  def
ghi]],
      { "abc", "def", "ghi" }
   )

   -- We break at punctuation.
   check("a$b cde", { "a", "$", "b", "cde" })

   -- We break at punctuation.
   check("a$b cde", { "a", "$", "b", "cde" })

   -- We break at punctuation.
   check("a$b cde", { "a", "$", "b", "cde" })

   -- We break at punctuation.
   check("a$b cde", { "a", "$", "b", "cde" })

   -- Weird whitespace is okay
   check("abc \t def \n\t ghi", { "abc", "def", "ghi" })

   -- Adjacent punctuation comes apart.
   check("$!@#", { "$", "!", "@", "#" })
end

return mod
