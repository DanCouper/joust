defmodule GameDataFixtures do
  alias Battleships.GameData, as: Data
  @doc "Directly create a full map of basic game data prior to guesses"
  def simple_populate_game_data do
    with {:ok, data} <- Data.initialise("1", "Dan"),
         {:ok, data} <- Data.add_second_player(data, "Nad"),
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
end
