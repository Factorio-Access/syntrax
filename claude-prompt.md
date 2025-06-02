Now that the basics are in place we need to prepare to add support for forks.  That is, splitting a track 3 ways.  We
will do so by adding `rpush` and `rpop` commands, as well as `reset`.  These manipulate the "rail stack", a stack of
rails *and* hand locations when the rail was placed.

What I mean by this is that:

- Rail 5, hand north
- Rail 5, hand south

Is a valid stack--the player might have passed over rail5  multiple times (though for now they can't, but that is coming in future work).

Your strategy is as follows:

- Add keyword tokens
- Add those to the AST
- Prepare the VM to e able to return structured runtime errors by:
  - Attaching spans to bytecode.
  - Amending the interface to allow for it.
  - Reusing the compilation error infrastructure.
  - Errors should point the user to the problematic code.
- Amend the VM as follows:
  - The user must supply the initial rail and iniitial hand direction.
  - A `rail_stack` is maintained where the entries are a hand direction and the index of the rail 
  - rpush and rpop manipulate it.
  - Reset clears it, and returns the hand to the initial rail and initial hand direction.
  - It must be possible to rpush and rpop the externally supplied initial rail, that is a program may start with rpush.
  - It is a runtime error if rpop is run on an empty stack.
  - The rail stack is global. It is not scoped.  Loops do not get their own.  Loops are free to have mismatching numbers of rpush and rpop in them.

Here is an example of a 3-way split, where all outgoing rails would be parallel.  Assume we're going to the east:

```
- Northmost rail
l r s reset
- Go back, then do the middle one
s s s reset
-- And the southmost
r s l
```

An example of rpush and rpop inside loops is this train station example from the less formal spec:

```
s s rpush [
  -- Go back to where the last station ended.
  rpop
  -- Save that.
  rpush
  -- Make the station off to the side:
  l l [ s ] rep 10
  -- Return to the mainline
  rpop
  -- Add a bit of straight rail for the next one
  s s s
  -- Save this, so it's picked up on the next iteration
  rpush
] rep 5 -- 5 stations.
```

Right now, our story around whether or not l and r rotate the hand is a bit unclear.  If the hand and initial rail are going north, then the desired behavior is:

```
-- Hand to nnw
l
-- rail from north to nnw gets pushed, hand nnw
rpush
```

Test your implementation and update public interfaces and documentation as appropriate.
