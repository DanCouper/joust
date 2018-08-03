defmodule NoughtsAndCrosses.GameData do
  @moduledoc """
  9-board noughts and crosses.

  Played on a 3-by-3 array of normal 3-by-3 boards. First player can place anywhere.
  Subsequent plays must be on the board that corresponds to the previous play.

  %{

  }
  """
  require IEx

  def create_player_data(name) when is_binary(name) do
    {:ok, %{name: name}}
  end

  def create_player_data(_), do: {:error, :invalid_name}

  def new_board, do: for i <- 1..9, into: %{}, do: {i, nil}

  def new_game_board, do: for i <- 1..9, into: %{}, do: {i, new_board()}

  def initialise(game_id) when is_binary(game_id) do
    game_data = %{
      id: game_id,
      game_type: :noughts_and_crosses,
      current_player: 1,
      registered_players: 0,
      max_players: 2,
      active_board: nil,
      game_board: new_game_board(),
      players: %{}
    }

    {:ok, game_data}
  end

  def initialise(_) do
    {:error, :invalid_game_id}
  end

  def add_player(%{registered_players: registered_players, max_players: max_players} = game_data, name) when registered_players < max_players do
    with {:ok, player_data} <- create_player_data(name) do
      updated_data = game_data
        |> put_in([:registered_players], registered_players + 1)
        |> put_in([:players, registered_players + 1], player_data)

      {:ok, updated_data}
    else
      err -> err
    end
  end

  def add_player(_game_data, _name) do
    {:error, :all_players_already_joined}
  end

  def take_move(%{active_board: nil} = game_data, board, cell) do
    updated_data = game_data
    |> put_in([:game_board, board, cell], game_data.current_player)
    |> put_in([:active_board], cell)
    |> put_in([:current_player], 2) # Always starts with first player then switches to second

    {:ok, updated_data, {:no_win}}
  end

  def take_move(%{active_board: active_board}, board, _cell) when board != active_board do
    {:error, :inactive_board}
  end

  def take_move(game_data, board, cell) do
    with {:ok, game_data} <- check_unplaced(game_data, board, cell) do
      updated_data = game_data
      |> put_in([:game_board, board, cell], game_data.current_player)

      cond do
        win_state?(updated_data.game_board, game_data.current_player) ->
          {:ok, updated_data, {:win}}
        draw_state?(updated_data.game_board) ->
          {:ok, updated_data, {:draw}}
        true ->
          updated_data = updated_data
          |> put_in([:active_board], cell)
          |> put_in([:current_player], (if game_data.current_player == 1, do: 2, else: 1))

          {:ok, updated_data, {:no_win}}
      end
    end
  end

  def draw_state?(game_board) do
    # NOTE this is totally dumb, it needs to check that no further possible moves can be made,
    # and this is not necessarily when every cell is populated.
    Enum.all?(game_board, fn {_, board} ->
      Enum.all?(board, fn {_, v} -> not is_nil(v) end)
    end)
  end

  def win_state?(current_board, current_player_number) do
    # NOTE this is pretty dumb, ideally I want to return the board keys that caused the win
    lines = [[1,2,3],[4,5,6],[7,8,9],[1,4,7],[2,5,8],[3,6,9],[1,5,9],[3,5,7]]

    Enum.any?(lines, fn line -> Enum.all?(line, fn n -> current_board[n] == current_player_number end) end)
  end

  def check_unplaced(game_data, board, cell) do
    case is_nil(game_data.game_board[board][cell]) do
      true -> {:ok, game_data}
      false -> {:error, :already_placed}
    end
  end
end
