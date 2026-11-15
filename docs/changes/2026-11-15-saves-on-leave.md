- The game now saves the moment it goes to the background or closes, and it tells you if a save ever fails.

## Backlog
- fixed: a change that waited for the next save (a smashed fence, a pushed car, a Podwózka story heard) was lost when iOS closed the game in the background
- fixed: a save that failed to write was never shown to the player
- fixed: the save's migration copy and NOWA GRA's copy of the old save were not checked; NOWA GRA now wipes nothing when its copy fails
- found: NOWA GRA does nothing visible when the old save's copy cannot be made (the player is not told why)
