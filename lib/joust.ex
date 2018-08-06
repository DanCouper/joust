defmodule Joust do
  @moduledoc """
  Joust is a simple game engine.

  ## ROADMAP

  Main functions should be delegated to this module: I like the main
  file to be the public API, I think it is a good pattern.

  The main function is the creation of a game, which initialises the
  main game data structure.

  This `%Joust{}` struct should have maniputation functions and getters/setters
  for specific properties/nested structures. The struct represents a game process,
  and should be structured:

  1. Some meta information regarding the game. This includes the name of the game,
     how many players it can/must have and whatever else is necessary. This should be,
     as much as possible, always consistent between games.
  2. Some setup information regarding the game. The UI _needs_ this information as
     an input when it sets up. This includes the size of the board if it has one.
     This changes on a per-game basis, but should be compiled; it cannot change once built.
     NOTE this should effectively be used as instructions to build the actual game data -
     it should be the initial input that allows the structure of that to be created.
  3. The actual game data. This is the thing that gets passed around the FSM.
     NOTE extracting it from the overall game struct removes a level of nesting,
     which keeps my sanity intact for a bit longer.

  Joust should not care about the interface, and should al;ways return consistent
  responses (`{:ok, data, [maybeAdditionalMetaInformation]}` or `{:error, reason}`).

  Games should go in the game library initially, with the intention to seperate
  to a different app. Logic could be built to allow run time loading of games,
  but it would be preferable to force compile-time loading as this simplifies
  the whole process.

  Once enough hgames have been built to understand the core commonalities of structure, move
  to using a behaviour to speed up generation. There should be a contract involved in
  building out the game backend which involves the game data structure, the game logic
  structure + any game-specific messages. Going further forward, the game frontend
  should be packaged (not necessarily the actual frontend, rather an SDK to add into it).

  Atom responses (basically error reasons) should, as much as is possible, be
  consistent. This means I can switch them to gettext keys: this will need more
  investigation, but the ideal is a set of common keys + a set of game-specific
  keys.

  The registry is a bit hmmm. It is necessary, necessitates a `via_tuple` function
  to do lookups. Need to have a think about how I can avoid that for testing, as it
  adds a layer of indirection, whereas I would like to be able to ignore it when
  testing individual games in isolation. Should be able to put a facade in front of it.

  State dumps will be important: need to test the FSMs by snapshotting the state
  then rehydrating an FSM using that snapshot. This would be extremely cool, as it
  enables time-travel.

  The FSM doesn't work for anything but a small set of usecases. Once I've built
  out a load of FSM-backed games, start to look at how the API changes for more complex
  games (look at decision trees etc. Digraph will work for some games).
  """

  @doc """
  Given a game type, spawn a game process with the game struct as the state.
  Return value is the game's ID, allowing lookup in the registry, rather than
  the game state itself
  """
  @spec initialise_new_game(atom()) :: {:ok, String.t()} | {:error, :nonexistant_game_type}
  defdelegate initialise_new_game(game_type), to: Joust.GameSupervisor
end
