# Syntrax Tutorial

## Introduction

Syntrax is a text-based language for designing Factorio train rail layouts. Instead of placing rails visually, you write commands that describe the track layout. This tutorial assumes you understand Factorio trains and want to create complex rail networks programmatically.

## Basic Rail Placement

Syntrax has three fundamental commands:

- `l` - Place a left-turning rail (curves 22.5 degrees counterclockwise)
- `r` - Place a right-turning rail (curves 22.5 degrees clockwise)  
- `s` - Place a straight rail

Commands execute sequentially. Writing `l r s` places a left turn, then a right turn, then a straight rail. Each rail connects to the previous one.

### Direction System

Rails connect using Factorio's 16-direction system. Each turn rotates your facing direction by one step (22.5 degrees). A complete circle requires 16 turns in the same direction.

## Sequences and Repetition

Square brackets group commands into sequences:

```
[l l s]
```

By itself, this is identical to writing `l l s` - brackets alone don't change behavior.

### The rep keyword

Sequences become powerful when combined with the `rep` keyword:

```
[l l s] rep 8
```

This repeats the entire bracketed pattern 8 times. The repetition count must be a positive integer.

Without `rep`, brackets are purely for grouping and readability - they don't affect execution.

### Nesting

Sequences can be nested:

```
[[s s] [l l]] rep 4
```

This creates 4 repetitions of: two straights followed by two lefts.

## Common Patterns

### Circles

A circle requires 16 turns of 22.5 degrees each:

```
[l] rep 16
```

Or with straight sections for a larger circle:

```
[l l s] rep 8
```

### Corners

A 90-degree right turn:

```
r r r r
```

More compact using repetition:

```
[r] rep 4
```

### S-Curves

An S-curve that shifts tracks sideways:

```
[l] rep 4 [r] rep 4
```

## Rail Stack and Forks

Syntrax provides three commands for managing position when creating track splits:

- `rpush` - Save current position and direction on a stack
- `rpop` - Restore the most recently saved position and direction
- `reset` - Clear the stack and return to the starting position

### Simple Fork

A Y-junction where two tracks split from one:

```
s s s rpush
l l s s s
rpop
r r s s s
```

This creates a straight section, then splits into left and right branches.

### Three-Way Split

For three parallel tracks splitting from one point:

```
rpush
l r s reset
s s s reset  
r s l
```

The `reset` command returns to the starting position for each branch.

### Station Sidings

Create multiple station sidings along a mainline:

```
s s rpush [
  rpop rpush
  l l [s] rep 10
  rpop
  s s s rpush
] rep 5
```

This pattern:
1. Returns to the last position with `rpop`
2. Saves it again with `rpush` 
3. Creates a siding with left turns and straight rails
4. Returns to mainline with `rpop`
5. Advances along mainline and saves position for next iteration

## Reference

### Commands
- `l` - Left turn (22.5° counterclockwise)
- `r` - Right turn (22.5° clockwise)
- `s` - Straight rail
- `rpush` - Save position/direction
- `rpop` - Restore position/direction
- `reset` - Return to starting position

### Syntax
- `[commands]` - Group commands in sequence
- `sequence rep n` - Repeat sequence n times
- Whitespace and newlines ignored
- `--` starts a comment to end of line

### Direction Math
- Full circle = 16 turns
- 90° turn = 4 turns
- 45° turn = 2 turns
- Each turn = 22.5°

Start experimenting with simple patterns and gradually combine them into complex rail networks. The key is breaking down layouts into repeatable components.