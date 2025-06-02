# VM Specification

To be amended as we move forward.

## VM State Overview

A VM has:

- An array of general-purpose registers.
- An array of bytecode (but represented as a lua table; see below).
- A graph of rails.
- A program counter register, `pc`.
- A "hand state".

## Values, operands,  and referring to registers

A value is represented as a Lua table. This is what the value 5 looks like:

```
{
   "source" = "value",
   "type" = "number",
   "argument" = 5,
}
```

Registers are a very similar lua table:

```
{
   "kind" = "register",
   "argument" = 1, -- the number of the register in the registers array
}
```

A register's type can be anything.  Registers themselves hold values.  The two tables above form a union called an
operand:

```
{
   "kind" = "value" | "register",
   "type" = "number", -- not present for registers.
   "argument" = register | literal,
}
```

To determine what a value is, we resolve it:

- If it isn't a register, we've got it alreadyh;
- If it is a register, we look up the register.

Bytecode parameters are always resolved.  It is an error if a register refers to another register.

## Basic form of Bytecode

Bytecode takes this form:

```
{
   "kind" = bytecode_kind,
   "arguments" = { operand, operand, operand... },
}
```

For ease of programmatic manipulation the arguments are not named. Most bytecode have at most 2.

The bytecode reference is later in the file.

## PC

Shouldn't need explanation

## The hand

There is an invisible-ish state in Syntrax, the hand.  If you look at syntrax what we have is basically complicated and
constrained turtle graphics.  When a user types "l", they are adding a left turn *and* rotating their hand left by
1/16th of a circle.  Directions are numeric, 0 is north, 4 is east, 8 is south, 12 is west.

Today it is not possible to disagree with the hand and the placed rail, but in the future it will be possible to move
the hand without placing rails, so the hand state must be maintained.

# Output

The output of the VM is a graph represented as a flat array.  Each entry is of the form:

```
{
   -- If this isn't an initial rail.
   parent = index,
   kind = "left" | "straight" | "right",
   incoming_direction = hand direction at the time of placement,
   outgoing_direction = direction of the hand after placement,
}
```

# Bytecode Reference

The bytecode are as follows:

### Left, Straight, Right

No operands.

Outputs the appropriate rail and changes the hand direction appropriately.

## JNZ: jump if not zero

Operands:

- A register or value.
- A relative offset to jump to.  This is position-independent code.

## Math

Operands:

- Destination: must be a register.
- Left: the first value.
- Right: the second value.
- op: "+" | "-" | "*" | "/": what to do.

Computes `left OP right` and writes it to the `register`.

## CMP

Operands:

- Destination: a register
- Value1: a value.
- value2: another value.
- op: "<" | "<=" | "==" | ">=" | ">" | "!="

Performs the comparison `value1 OP value2`.  If this comparison is true, write 1 to the destination register;
otherwise, writes 0.

## Mov

Operand:

- Destination: a register
- value: a value or register

Resolves value, and puts it in destination.  E.g. `MOV r1 5` sets `r1` to `5`.

# Pretty Printable Format

We define a format for printing bytecode:

```
bytecode k(v) k(v) k(v)...
```

Where k is the kind of the operand, and v the value. For example, `r1 = 2 + r2` would compile as:

```
MATH r(1) v(2) r(2) op(+)
```

We can add an optional label before it:

```
l1: math r(1) v(2) r(2) op(+)
```

And then, we print our relative jumps to the labels, at least if their value is a value and not a register:

```
jmp l1
```

Or, if it is a register,

```
jpm r(5)
```

# Claude Directions

- Be sure to implement using enums like how we do in the lexer.
- Think hard about the output, because it's subtle.
