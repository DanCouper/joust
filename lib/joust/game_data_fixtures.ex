defmodule GameDataFixtures do
  alias Joust.Games.Supervisor, as: Manager
  alias Battleships.GameData, as: Data
  alias Battleships.Game, as: Game
  @doc """
  Directly create a full map of basic game data prior to guesses

  For testing the GameData module directly.
  """
  def simple_populate_game_data do
    with {:ok, data} <- Data.initialise("1"),
         {:ok, data} <- Data.add_player(data, "Dan"),
         {:ok, data} <- Data.add_player(data, "Nad"),
         {:ok, data} <- Data.place_ship(data, :player1, :carrier, :vertical, 1, 1),
         {:ok, data} <- Data.place_ship(data, :player1, :battleship, :vertical, 2, 1),
         {:ok, data} <- Data.place_ship(data, :player1, :cruiser, :vertical, 3, 1),
         {:ok, data} <- Data.place_ship(data, :player1, :destroyer, :vertical, 4, 1),
         {:ok, data} <- Data.place_ship(data, :player1, :destroyer, :vertical, 5, 1),
         {:ok, data} <- Data.place_ship(data, :player1, :submarine, :vertical, 6, 1),
         {:ok, data} <- Data.place_ship(data, :player1, :submarine, :vertical, 7, 1),
         {:ok, data} <- Data.place_ship(data, :player2, :carrier, :vertical, 1, 1),
         {:ok, data} <- Data.place_ship(data, :player2, :battleship, :vertical, 2, 1),
         {:ok, data} <- Data.place_ship(data, :player2, :cruiser, :vertical, 3, 1),
         {:ok, data} <- Data.place_ship(data, :player2, :destroyer, :vertical, 4, 1),
         {:ok, data} <- Data.place_ship(data, :player2, :destroyer, :vertical, 5, 1),
         {:ok, data} <- Data.place_ship(data, :player2, :submarine, :vertical, 6, 1),
         {:ok, data} <- Data.place_ship(data, :player2, :submarine, :vertical, 7, 1)
      do
        data
    end
  end

  @doc """
  Create a supervised game, and place all ships.

  For testing the application. Note that all `Game` functions
  accept the game ID, which is used to look up the PID in the Registry.
  """
  def setup_game_board_4real do
    {:ok, id} = Manager.start_game(:battleships)

    Game.add_player(id, "Dan")
    Game.add_player(id, "Nad")
    Game.position_ship(id, :player1, :carrier, :vertical, 1, 1)
    Game.position_ship(id, :player1, :battleship, :vertical, 2, 1)
    Game.position_ship(id, :player1, :cruiser, :vertical, 3, 1)
    Game.position_ship(id, :player1, :destroyer, :vertical, 4, 1)
    Game.position_ship(id, :player1, :destroyer, :vertical, 5, 1)
    Game.position_ship(id, :player1, :submarine, :vertical, 6, 1)
    Game.position_ship(id, :player1, :submarine, :vertical, 7, 1)
    Game.position_ship(id, :player2, :carrier, :vertical, 1, 1)
    Game.position_ship(id, :player2, :battleship, :vertical, 2, 1)
    Game.position_ship(id, :player2, :cruiser, :vertical, 3, 1)
    Game.position_ship(id, :player2, :destroyer, :vertical, 4, 1)
    Game.position_ship(id, :player2, :destroyer, :vertical, 5, 1)
    Game.position_ship(id, :player2, :submarine, :vertical, 6, 1)
    Game.position_ship(id, :player2, :submarine, :vertical, 7, 1)

    id
  end
end
