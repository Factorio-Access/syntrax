#!/usr/bin/env lua
--[[
Syntrax CLI - Development and debugging tool for the Syntrax language

This is NOT part of the public API. It's a development utility that provides
access to internal modules for debugging and testing purposes.

Usage:
  syntrax-cli.lua [options] [file]
  syntrax-cli.lua [options] -c <code>

Options:
  -h, --help          Show this help message
  -c <code>           Compile and run code from command line
  -o, --output <fmt>  Output format: rails (default), bytecode, ast, all
  -q, --quiet         Quiet mode (only show output, no headers)
  --version           Show version information

Examples:
  syntrax-cli.lua program.syn           # Run a file
  syntrax-cli.lua -c "[l r] rep 4"      # Run code directly
  syntrax-cli.lua -o bytecode file.syn  # Show only bytecode
  syntrax-cli.lua -o all -c "l r s"     # Show all stages
]]

-- For the public API
local Syntrax = require("syntrax")

-- For debugging features, we need internal modules
local Parser = require("syntrax.parser")
local Compiler = require("syntrax.compiler")
local Vm = require("syntrax.vm")
local Ast = require("syntrax.ast")

-- CLI argument parsing
local function parse_args(args)
   local options = {
      output = "rails",
      quiet = false,
      help = false,
      version = false,
      code = nil,
      file = nil,
   }
   
   local i = 1
   while i <= #args do
      local arg = args[i]
      
      if arg == "-h" or arg == "--help" then
         options.help = true
         return options
      elseif arg == "--version" then
         options.version = true
         return options
      elseif arg == "-q" or arg == "--quiet" then
         options.quiet = true
      elseif arg == "-o" or arg == "--output" then
         i = i + 1
         if i > #args then
            return nil, "Option " .. arg .. " requires an argument"
         end
         local fmt = args[i]
         if fmt ~= "rails" and fmt ~= "bytecode" and fmt ~= "ast" and fmt ~= "all" then
            return nil, "Invalid output format: " .. fmt
         end
         options.output = fmt
      elseif arg == "-c" then
         i = i + 1
         if i > #args then
            return nil, "Option -c requires an argument"
         end
         options.code = args[i]
      elseif arg:sub(1, 1) == "-" then
         return nil, "Unknown option: " .. arg
      else
         if options.file then
            return nil, "Multiple input files specified"
         end
         options.file = arg
      end
      
      i = i + 1
   end
   
   -- Validate options
   if options.code and options.file then
      return nil, "Cannot specify both -c and input file"
   end
   
   if not options.code and not options.file and not options.help and not options.version then
      return nil, "No input specified (use -c for code or provide a file)"
   end
   
   return options
end

local function show_help()
   print([[
Syntrax CLI - Command line interface for the Syntrax language

Usage:
  syntrax-cli.lua [options] [file]
  syntrax-cli.lua [options] -c <code>

Options:
  -h, --help          Show this help message
  -c <code>           Compile and run code from command line
  -o, --output <fmt>  Output format: rails (default), bytecode, ast, all
  -q, --quiet         Quiet mode (only show output, no headers)
  --version           Show version information

Examples:
  syntrax-cli.lua program.syn           # Run a file
  syntrax-cli.lua -c "[l r] rep 4"      # Run code directly
  syntrax-cli.lua -o bytecode file.syn  # Show only bytecode
  syntrax-cli.lua -o all -c "l r s"     # Show all stages
]])
end

local function show_version()
   print("Syntrax version 0.1.0")
   print("A domain-specific language for Factorio train layouts")
end

-- Pretty print AST
local function print_ast(node, indent)
   indent = indent or 0
   local prefix = string.rep("  ", indent)
   
   if node.type == Ast.NODE_TYPE.SEQUENCE then
      print(prefix .. "sequence:")
      if #node.statements == 0 then
         print(prefix .. "  (empty)")
      else
         for i, stmt in ipairs(node.statements) do
            print_ast(stmt, indent + 1)
         end
      end
   elseif node.type == Ast.NODE_TYPE.LEFT then
      print(prefix .. "left")
   elseif node.type == Ast.NODE_TYPE.RIGHT then
      print(prefix .. "right")
   elseif node.type == Ast.NODE_TYPE.STRAIGHT then
      print(prefix .. "straight")
   elseif node.type == Ast.NODE_TYPE.RPUSH then
      print(prefix .. "rpush")
   elseif node.type == Ast.NODE_TYPE.RPOP then
      print(prefix .. "rpop")
   elseif node.type == Ast.NODE_TYPE.RESET then
      print(prefix .. "reset")
   elseif node.type == Ast.NODE_TYPE.REPETITION then
      print(prefix .. "repetition:")
      print(prefix .. "  count: " .. node.count)
      print(prefix .. "  body:")
      print_ast(node.body, indent + 2)
   end
end

-- Main execution
local function main(args)
   -- Parse arguments
   local options, err = parse_args(args)
   if not options then
      io.stderr:write("Error: " .. err .. "\n")
      io.stderr:write("Use -h for help\n")
      os.exit(1)
   end
   
   -- Handle help and version
   if options.help then
      show_help()
      os.exit(0)
   end
   
   if options.version then
      show_version()
      os.exit(0)
   end
   
   -- Get input
   local input
   if options.code then
      input = options.code
   else
      local file = io.open(options.file, "r")
      if not file then
         io.stderr:write("Error: Could not open file '" .. options.file .. "'\n")
         os.exit(1)
      end
      input = file:read("*a")
      file:close()
   end
   
   -- Parse
   local ast, parse_err = Parser.parse(input)
   if parse_err then
      io.stderr:write("Parse error: " .. parse_err.message .. "\n")
      if parse_err.span then
         local l1, c1 = parse_err.span:get_printable_range()
         io.stderr:write(string.format("  at line %d, column %d\n", l1, c1))
      end
      os.exit(1)
   end
   assert(ast, "Parser returned nil AST without error")
   
   -- Show AST if requested
   if options.output == "ast" or options.output == "all" then
      if not options.quiet then
         print("=== Abstract Syntax Tree ===")
      end
      print_ast(ast)
      if options.output == "ast" then
         os.exit(0)
      end
      if not options.quiet and options.output == "all" then
         print()
      end
   end
   
   -- Compile
   local bytecode = Compiler.compile(ast)
   
   -- Show bytecode if requested
   if options.output == "bytecode" or options.output == "all" then
      if not options.quiet then
         print("=== Bytecode ===")
      end
      print(Compiler.format_bytecode_listing(bytecode))
      if options.output == "bytecode" then
         os.exit(0)
      end
      if not options.quiet and options.output == "all" then
         print()
      end
   end
   
   -- Execute
   local vm = Vm.new()
   vm.bytecode = bytecode
   local rails, runtime_err = vm:run()
   
   if runtime_err then
      io.stderr:write("Runtime error: " .. runtime_err.message .. "\n")
      if runtime_err.span then
         local l1, c1 = runtime_err.span:get_printable_range()
         io.stderr:write(string.format("  at line %d, column %d\n", l1, c1))
      end
      os.exit(1)
   end
   
   assert(rails)
   
   -- Show rails output
   if options.output == "rails" or options.output == "all" then
      if not options.quiet then
         print("=== Rails Output ===")
         print(string.format("Generated %d rails:", #rails))
      end
      
      for i, rail in ipairs(rails) do
         local parent_str = rail.parent and string.format("from rail %d", rail.parent) or "initial"
         print(string.format(
            "Rail %d: %s (%s, %s->%s)",
            i,
            rail.kind,
            parent_str,
            Vm.format_direction(rail.incoming_direction),
            Vm.format_direction(rail.outgoing_direction)
         ))
      end
      
      if not options.quiet then
         print(string.format("\nFinal direction: %s", Vm.format_direction(vm.hand_direction)))
         
         -- Summary
         local turn_count = 0
         for _, rail in ipairs(rails) do
            if rail.kind ~= "straight" then
               turn_count = turn_count + 1
            end
         end
         print(string.format("Summary: %d rails (%d straight, %d turns)", 
            #rails, #rails - turn_count, turn_count))
      end
   end
end

-- Run main with command line arguments
main(arg or {})