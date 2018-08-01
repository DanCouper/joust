# Joust

## Thoughts

The GameData is now too unwieldy.

A game struct needs:

1. Some meta information regarding the game. This includes the name of the game, how many players it can/must have and whatever else is necessary. This should be, as much as possible, always consistent between games.
2. Some setup information regarding the game. The UI _needs_ this information as an input when it sets up. This includes the size of the board if it has one. This changes on a per-game basis, but should be compiled; it cannot change once built. NOTE this should effectively be used as instructions to build the actual game data - it should be the initial input that allows the structure of that to be created.
3. The actual game data. This is the thing that gets passed around the FSM. NOTE extracting it from the overall game struct removes a level of nesting, which keeps my sanity intact for a bit longer.

