# Syntrax Codebase Overview

## Project Purpose
Syntrax is a domain-specific language for specifying Factorio train layouts as part of the Factorio Access mod, which makes Factorio accessible to blind players. The language addresses the inaccessibility of Factorio's rail planner by providing a text-based way to specify rail layouts.

## Language Basics
- Basic commands: `l` (left curve), `r` (right curve), `s` (straight)
- Sequences: `[commands]` - groups commands, can be empty
- Repetition: `[pattern] rep n` - repeats pattern n times
- Empty programs are valid (useful as a no-op or placeholder)
- Example: `[l l s] rep 8` creates a complete circle with 8 repetitions of left-left-straight
- Note: Only square brackets `[]` are allowed for sequences (parentheses and curly braces reserved for future use)

## Technical Constraints
- Must use Lua 5.2 (Factorio's Lua version)
- Targeting Factorio 2.0 (different rail shapes from 1.1)
- Coordinates provided by Factorio engine at runtime via LuaRailEnd API

## Architecture Overview

### Compilation Pipeline
lexer → AST → VM bytecode → execution

The pipeline follows a traditional compiler architecture:

### Core Modules

#### 1. Lexer (`syntrax/lexer.lua`)
- **Purpose**: Tokenizes Syntrax source code into a token tree
- **Key Design Decisions**:
  - Uses a "token tree" approach inspired by Rust - tokens can be simple or bracketed groups
  - Non-standard implementation due to Lua string processing performance (O(N²) for many operations)
  - Two-phase approach: first splits at possible token boundaries, then builds typed tokens
- **Token Types**:
  - `L`, `R`, `S` - directional commands
  - `REP` - repetition keyword
  - `IDENTIFIER` - generic identifiers
  - `NUMBER` - numeric literals
  - `TREE` - bracketed token groups
- **Bracket Matching**: Handles `()`, `[]`, `{}` with proper nesting and error reporting

#### 2. Span (`syntrax/span.lua`)
- **Purpose**: Tracks source text locations for error reporting
- **Features**:
  - Immutable objects representing text ranges (start/stop character indices)
  - Lazy line/column resolution for human-readable error messages
  - Merge operation to combine spans as larger constructs are built

#### 3. Errors (`syntrax/errors.lua`)
- **Purpose**: Structured error reporting
- **Components**:
  - Error codes enum for programmatic handling
  - Error builder pattern for constructing errors with notes
  - Support for multiple notes with optional source locations
- **Current Error Codes**:
  - `INVALID_TOKEN` - unrecognized token
  - `BRACKET_NOT_CLOSED` - unclosed bracket at EOF
  - `BRACKET_MISMATCH` - mismatched bracket types (e.g., `(]`)

#### 4. Compilation Result (`syntrax/compilation_result.lua`)
- **Purpose**: Manages compilation pipeline state
- **Features**:
  - Holds either a successful result or an error
  - Simple container for compilation outcomes

### Testing Infrastructure
- **Framework**: LuaUnit (local copy included)
- **Helper Libraries**: Serpent for debugging output (use with `nocode = true`)
- **Test Organization**: Module-specific test files in `syntrax/tests/`
- **Run Tests**: `lua tests.lua`

## Development Patterns

### Error Handling
- Errors are first-class objects with structured information
- Functions return `result, error` pairs (nil result on error)
- Error builder pattern for rich error messages with contextual notes

### Token Tree Approach
The lexer produces a hierarchical structure where bracketed expressions are pre-parsed into trees. This simplifies later parsing stages by handling bracket matching early and providing a natural recursive structure.

### Performance Considerations
- Custom lexer implementation to avoid Lua string performance pitfalls
- Pattern matching used carefully to avoid O(N²) behavior
- Span resolution is lazy to avoid unnecessary line counting

## Language Compilation

### Minimal Subset
The "minimal subset" currently consists of just l/r/s commands. For example:
```
-- Full syntax
[l s r] rep 3
-- Minimal subset (after expansion)
l s r l s r l s r
```

This will be extended as features like variables and forks are added.

### VM Design
The VM will include:
- Registers (effectively infinite array)
- List of rail placement commands
- Bytecodes for primitive commands (l/r/s)
- Bytecodes for constants and control flow (decrement-and-jump)

The language exposes only bounded repetition constructs, ensuring programs always terminate in a fixed number of steps despite the VM being Turing-complete.

## Factorio Integration
- Will use mock interface with 16 directions enum
- Abstract rail types to be replaced with concrete values at runtime
- Multiple rail types exist based on runtime circumstances

## Next Steps
1. **Parser**: Convert token trees into an abstract syntax tree (current priority)
2. **VM Bytecode Generation**: Transform AST to VM instructions
3. **Extended Features**: Variables, flips, stacks, railrefs as described in the proposal

## Development Notes
- Test-driven development using LuaUnit
- Separate from Factorio runtime for easier testing
- The `COMPILATION_STATE` enum in compilation_result.lua is a remnant and can be removed