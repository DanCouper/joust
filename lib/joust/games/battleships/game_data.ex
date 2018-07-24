defmodule Battleships.GameData do
  @moduledoc """
  ## Overview

  The game data for battleships, to be passed through
  the FSM that controls the game.

  The data is (by necessity) nested. This file is structured from
  inner -> outer, each structure sitting inside the next, with
  coordinates at the base.

  ## Coordinate/s

  The base data structure is an `{x, y}` coordinate. This is used
  to define the position of [parts of] ships, and to make guesses
  about those positions.

  ## Ship/s

  Each player has a set of ships, taken from an allowed list.
  Each ship is represented as a MapSet of coordinates representing
  its position, and a second MapSet that represents those coordinates
  that have been correctly guessed by the other player.

  The game allows horizontal and vertical placement of ships.

  ## Board/s

  Each player has a board. The board is just a map of ships, with
  auto-incrementing integer keys (the map makes lookup/updating
  simpler than were it a list data structure)

  ## Player/s

  The `Players` map contains two `Player` maps under the `player1` and `player2` keys.
  """

  # CONSTRAINTS

  @board_range 1..10
  @ship_types %{
      carrier: %{size: 5, allowed: 1},
      battleship: %{size: 4, allowed: 1},
      cruiser: %{size: 3, allowed: 1},
      destroyer: %{size: 2, allowed: 2},
      submarine: %{size: 1, allowed: 2}
    }

  # COORDINATES

  @typedoc "The index value for a column on a 2d grid"
  @type col :: integer()
  @typedoc "The index value for a row on a 2d grid"
  @type row :: integer()
  @typedoc "A single `{x, y}` coordinate on a 2d grid"
  @type coordinate :: {col(), row()}


  @spec new_coord(col(), row()) :: {:ok, coordinate()} | {:error, :invalid_coordinate}
  def new_coord(col, row)
  when col in @board_range and row in @board_range do
    {:ok, {col, row}}
  end

  def new_coord(_col, _row) do
    {:error, :invalid_coordinate}
  end

  @typedoc "The possible types of ship, represented by atoms. REVIEW problematic, would rather generate from config."
  @type ship_type :: :carrier | :battleship | :cruiser | :destroyer | :submarine
  @type direction :: :horizontal | :vertical

  @type ship :: %{type: ship_type(), coordinates: MapSet.t(), guessed_coordinates: MapSet.t()}

  @doc """
  Generate a list of the ships initially available to a given player. This can
  then be used to check if a player has placed all their ships or not.
  """
  @spec available_ships(map()) :: [ship_type()]
  def available_ships(ship_types \\ @ship_types) do
    Enum.flat_map(ship_types, fn {type, %{allowed: n}} ->
      for _ <- 1..n, do: type
    end)
  end

  @doc """
  Generate a new map representing a single ship.
  """
  @spec new_ship(ship_type(), direction(), coordinate()) :: {:ok, ship()} | {:error, :atom}
  def new_ship(type, dir, start_coord) do
    with [_ | _] = offsets <- offsets(type, dir),
         coordinates <- add_coordinates(offsets, start_coord) do
      {:ok, %{type: type, coordinates: coordinates, guessed_coordinates: MapSet.new()}}
    else
      error -> error
    end
  end

  @spec offsets(ship_type(), direction()) :: [{col(), row()}]
  def offsets(type, direction) do
    0..(get_in(@ship_types, [type, :size]) - 1)
    |> Enum.map(fn offset ->
      case direction do
        :horizontal -> {offset, 0}
        :vertical -> {0, offset}
      end
    end)
  end

  @spec add_coordinates([coordinate()], coordinate()) :: MapSet.t(coordinate()) | {:error, :invalid_coordinate}
  def add_coordinates(offsets, start_coordinate) do
    Enum.reduce_while(offsets, MapSet.new(), fn offset, acc ->
      add_coordinate(acc, start_coordinate, offset)
    end)
  end

  @spec add_coordinate(MapSet.t(coordinate()), coordinate(), coordinate()) :: {:cont, MapSet.t(coordinate())} | {:halt, {:error, :invalid_coordinate}}
  def add_coordinate(coordinates, {col, row}, {col_offset, row_offset}) do
    case new_coord(col + col_offset, row + row_offset) do
      {:ok, coordinate} ->
        {:cont, MapSet.put(coordinates, coordinate)}

      {:error, :invalid_coordinate} ->
        {:halt, {:error, :invalid_coordinate}}
    end
  end

  @type ship_key :: non_neg_integer()
  @typedoc "A player board, represented as a map of ships, each with a unique key"
  @type board :: %{ship_key() => ship()}

  @spec new_board :: %{}
  def new_board, do: %{}

  @spec place_ship(board(), ship()) :: board() | {:error, :overlapping_ship}
  def place_ship(board, ship) do
    if overlaps?(board, ship) do
      {:error, :overlapping_ship}
    else
      Map.put(board, generate_key(board), ship)
    end
  end

  def generate_key(existing_board) do
    existing_board
    |> Map.keys()
    |> length
  end

  @spec overlaps?(board(), ship()) :: boolean()
  def overlaps?(board, new_ship) do
    Enum.any?(board, fn existing_ship ->
      not MapSet.disjoint?(existing_ship.coordinates, new_ship.coordinates)
    end)
  end

  @doc """
  A guess searches the board to check if the guessed coordinate matches that of
  a ship. It returns a tuple that describes

  a. if it is a hit or a miss
  b. if a hit, what the type of ship was (:none if a miss),
  c. if a hit, whether the ship was sunk (:none if not sunk)
  c. if the guess resulted in a game win
  d. the new state of the board after the guess
  """
  @spec guess(board(), coordinate()) :: {:hit | :miss, :none | ship_type(), :sunk | :afloat, :win | :no_win, board()}
  def guess(board, coordinate) do
    Enum.find_value(board, fn {key, ship} ->
      if MapSet.member?(ship.coordinates, coordinate) do
        # Good guess, update accordingly
        guessed_coordinates = MapSet.put(ship.guessed_coordinates, coordinate)
        updated_ship = %{ship | guessed_coordinates: guessed_coordinates}
        {:hit, ship.type, sunk_check(updated_ship), win_check(board), Map.put(board, key, updated_ship)}
      else
        # Bad guess, return as-is
        {:miss, :none, :afloat, :no_win, board}
      end
    end)
  end

  @spec sunk_check(ship()) :: :sunk | :no_sinking
  def sunk_check(ship), do: if sunk?(ship), do: :sunk, else: :afloat

  @spec win_check(board()) :: :win | :no_win
  def win_check(board), do: if all_sunk?(board), do: :win, else: :no_win

  @spec sunk?(ship()) :: boolean()
  def sunk?(ship), do: MapSet.equal?(ship.coordinates, ship.guessed_coordinates)

  @spec all_sunk?(board()) :: boolean()
  def all_sunk?(board), do: Enum.all?(board, &sunk?(&1))


  @type player :: %{
    name: String.t(),
    board: board(),
    ships_to_place: [ship_type()],
    correct_guesses: MapSet.t(coordinate()),
    incorrect_guesses: MapSet.t(coordinate())
  }

  @type data :: %{id: String.t(), player1: player(), player2: player() | nil}

  @spec create_player_data(String.t()) :: player()
  def create_player_data(name) do
    %{name: name, board: new_board(), ships_to_place: available_ships(), correct_guesses: MapSet.new(), incorrect_guesses: MapSet.new()}
  end

  @spec initialise(String.t(), String.t()) :: data()
  def initialise(game_id, p1_name), do: %{id: game_id, player1: create_player_data(p1_name), player2: nil}

  @spec add_second_player(data(), String.t()) :: data()
  def add_second_player(game_data, p2_name), do: %{game_data | player2: create_player_data(p2_name)}


end
