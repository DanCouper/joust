defmodule Battleships.GameStatem do
  @moduledoc """
  The FSM that controls the game state. Uses `gen_statem`.
  """
  use GenStateMachine

  alias Battleships.GameData, as: Data

  @type state ::
          :initialised
          | :players_setup
          | :players_set
          | :player1_turn
          | :player2_turn
          | :player1_win_check
          | :player2_win_check
          | :game_over

  ## CLIENT ACTIONS

  @doc """
  The state machine will initilise when a player starts it. At this point,
  the only possible action is to add another player.

  The data in the state machine is initialised with a new Player struct containing
  the player who initialised the game, and the state is set to :initialised
  """
  def start_link(game_id, p1_name) do
    GenStateMachine.start_link(__MODULE__, {game_id, p1_name}, name: game_id)
  end

  @doc """
  Adding another player should transition the state to `players_set` which is
  a bad name but it'll do for the minute (REVIEW possibly `players_ready`?)
  """
  def add_player(game_id, p2_name) do
    GenStateMachine.call(game_id, {:add_player, p2_name})
  end


  def position_ship(game_id, player, type, dir, col, row, dir) do
    GenStateMachine.call(game_id, {:position_ship, player, type, dir, col, row})
  end

  @doc """
  If a player has positioned their ships and passes that message on to the state
  machine, _either_ the state will not change (the other player has yet to
  finish positioning), _or_ both fleets are in position and the game can begin.

  This can be called by either player once they've placed their ships.
  """
  def set_ship_placement(game_id) do
    GenStateMachine.call(game_id, :set_ship_placement)
  end

  @doc """
  Once a player switches, the state will switch to that players' win check.
  """
  def guess_coordinate(game_id) do
    GenStateMachine.call(game_id, :guess_coordinate)
  end

  @doc """
  If the win check comes up trumps, it's game over. Otherwise, state will switch
  back to the other players turn.
  TODO make the logic a bit less messy server-side
  """
  def win_check(game_id, win_or_not) do
    GenStateMachine.call(game_id, {:win_check, win_or_not})
  end

  ## SERVER CALLBACKS

  @impl true
  def init({game_id, p1_name}) do
    game_data = Data.initialise(game_id, p1_name)
    {:ok, :initialised, game_data}
  end

  @impl true
  def handle_event({:call, from}, {:add_player, p2_name}, :initialised, game_data) do
    game_data = Data.add_second_player(game_data, p2_name)
    reply = [{:reply, from, {:ok, game_data}}]

    {:next_state, :players_setup, game_data, reply}
  end

  @impl true
  def handle_event({:call, from}, {:position_ship, player, type, dir, col, row}, :players_setup, game_data) do
    player = Map.get(game_data, player)

    case player.ships_to_place do
      [] ->
        {:keep_state_and_data, [{:reply, from, "All player ships already placed."}]}
      _available_ships ->
        place_ship_on_board(from, game_data, player, type, dir, col, row)
    end
  end

  defp place_ship_on_board(from, game_data, player, type, dir, col, row) do
    current_player = Map.get(game_data, player)
    updated_player_data = place_player_ship_on_board(current_player, type, dir, col, row)

    case updated_player_data do
      {:ok, data} ->
        game_data = Map.put(game_data, player, data)
        {:keep_state, game_data, [{:reply, from, {:ok, game_data}}]}
      _ ->
        {:keep_state_and_data, [{:reply, from, {:error, "Something went wrong"}}]}
    end
  end

  defp place_player_ship_on_board(player, type, dir, col, row) do
    with {:ok, coordinate} <- Data.new_coord(col, row),
        {:ok, ship} <- Data.new_ship(type, dir, coordinate),
        %{} = updated_board <- Data.place_ship(player.board, ship)
    do
      {:ok, %{ player | board: updated_board, ships_to_place: List.delete(player.ships_to_place, type)}}
    else
      _ -> :error
    end
  end

  @impl true
  def handle_event({:call, from}, :set_ship_placement, :players_set, game_data) do
    case {game_data.player1.ships_to_set, game_data.player2.ships_to_set} do
      {[], []} ->
        reply = [{:reply, from, {:ok, "Both players' ships are down, good to go!"}}]
        {:next_state, :player1_turn, game_data, reply}

      _ ->
        reply = [{:reply, from, {:ok, "Your opponent hasn't finished placing their fleet yet, hang on."}}]
        {:keep_state_and_data, reply}
    end
  end

  @impl true
  def handle_event({:call, from}, {:guess_coordinate, player, coordinate}, state, game_data)
      when state in [:player1_turn, :player2_turn] do
    {:next_state, switch_turn_state(state), game_data,
     [
       {:reply, from,
        {:ok, "#{player_from_state(state)} gone done a guess, let's check if they've won."}}
     ]}
  end

  @impl true
  def handle_event({:call, from}, {:win_check, win_or_not}, state, game_data)
      when state in [:player1_win_check, :player2_win_check] do
    case win_or_not do
      :no_win ->
        {:next_state, switch_turn_state(state), game_data,
         [
           {:reply, from,
            {:ok, "#{player_from_state(state)} didn't win, it's now #{
              player_from_state(switch_turn_state(state))
            }'s turn to guess.'"}}
         ]}

      :win ->
        {:next_state, :game_over, game_data,
         [{:reply, from, {:ok, "#{player_from_state(state)} Won"}}]}
    end
  end

  # Catch all to prevent errors - does nothing but return :error
  # if attempt made to enter impossible state.
  @impl true
  def handle_event({:call, from}, _event_content, _state, _data) do
    {:keep_state_and_data, [{:reply, from, :error}]}
  end

  defp switch_turn_state(state) do
    case state do
      :player1_turn -> :player1_win_check
      :player2_turn -> :player2_win_check
      :player1_win_check -> :player2_turn
      :player2_win_check -> :player1_turn
    end
  end

  defp player_from_state(state) when state in [:player1_turn, :player1_win_check], do: "Player 1"
  defp player_from_state(state) when state in [:player2_turn, :player2_win_check], do: "Player 2"



end
