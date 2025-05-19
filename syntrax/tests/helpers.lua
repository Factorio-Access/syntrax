local mod = {}

--- Deep copy the table, breaking any loops/recursive references. Useful to get luaunit to print in a way that lets one
--  paste values from the terminal.
function mod.deepcopy_unrecursive(tab)
   local res = {}

   for k, v in pairs(tab) do
      if type(v) == "table" then v = mod.deepcopy_unrecursive(v) end
      res[k] = v
   end

   return res
end

return mod
