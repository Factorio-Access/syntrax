# Syntrax

A Lua library for the Factorio Access mod that compiles text-based rail layout descriptions into placement instructions. This library enables blind players to plan train networks using a simple text syntax instead of the visual rail planner.

**Status: Work in Progress** - This is an early development version. The API and language features are subject to change.

## Overview

Syntrax is designed to be integrated into the Factorio Access mod. It provides a compiler that transforms text descriptions of rail layouts into a sequence of rail placements that can be executed by the mod.

### Language Example

```
l r s              -- Place left, right, straight rails
[l l s] rep 8      -- Create a circle with 8 repetitions
```

## Installation

Syntrax requires Lua 5.2 (Factorio's Lua version). Add the syntrax directory to your project.

## Library API

The library exposes a single public function:

```lua
local Syntrax = require("syntrax")

-- Compile and execute Syntrax code
local rails, error = Syntrax.execute("l r s")

if error then
    -- Handle compilation error
    print("Error: " .. error.message)
else
    -- Process rail placements
    for i, rail in ipairs(rails) do
        print(string.format("Rail %d: %s at direction %d", 
            i, rail.kind, rail.outgoing_direction))
    end
end
```

### Return Values

The `execute` function returns:
- `rails` - Array of rail placement instructions (or nil on error)
- `error` - Error object with code, message, and source location (or nil on success)

Each rail in the array contains:
- `kind` - "left", "right", or "straight"
- `parent` - Index of the previous rail (nil for first rail)
- `incoming_direction` - Direction before placing (0-15, where 0=north)
- `outgoing_direction` - Direction after placing

## Development Tools

While Syntrax is primarily a library, it includes several utilities for development and debugging:

### Command Line Interface

`syntrax-cli.lua` - Debugging tool for testing Syntrax programs:

```bash
# Test a program
lua syntrax-cli.lua -c "[l r s] rep 4"

# Show compilation stages
lua syntrax-cli.lua -c "l r s" -o all

# Run from file
lua syntrax-cli.lua program.syn
```

### Other Tools

- `print-ast.lua` - Display parsed syntax trees
- `print-vm.lua` - Show VM bytecode execution
- `check-lua.sh` - Run static analysis

## Testing

Run the test suite:
```bash
lua tests.lua
```

## Language Reference

See `spec.md` for the complete language specification.

## Implementation Notes

- All modules except the main `syntrax` module are internal implementation details
- The CLI and other tools are for development/debugging, not part of the public API
- Direction values (0-15) match Factorio's 16-direction system
- See `claude.md` for architecture and implementation details

## License

See LICENSE file for details.