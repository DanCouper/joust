defmodule Battleships.GameStatem do
  @moduledoc """
  The FSM that controls the game state. Uses `gen_statem`.
  """
  use GenStateMachine

  alias Battleships.GameData, as: Data

  @type state ::
          :initialised
          | :players_setup
          | :player1_turn
          | :player2_turn
          | :game_over

  ## CLIENT ACTIONS

  @doc """
  The state machine will initilise when a player starts it. At this point,
  the only possible action is to add another player.

  The data in the state machine is initialised with a new Player struct containing
  the player who initialised the game, and the state is set to :initialised
  """
  def start_link(game_id, p1_name) do
    GenStateMachine.start_link(__MODULE__, {game_id, p1_name}, name: via_tuple(game_id))
  end

  @doc """
  Adding another player should transition the state to `players_set` which is
  a bad name but it'll do for the minute (REVIEW possibly `players_ready`?)
  """
  def add_player(game_id, p2_name) do
    GenStateMachine.call(via_tuple(game_id), {:add_player, p2_name})
  end


  def position_ship(game_id, player, type, dir, col, row) do
    GenStateMachine.call(via_tuple(game_id), {:position_ship, player, type, dir, col, row})
  end

  @doc """
  If a player has positioned their ships and passes that message on to the state
  machine, _either_ the state will not change (the other player has yet to
  finish positioning), _or_ both fleets are in position and the game can begin.

  This can be called by either player once they've placed their ships.
  """
  def set_ship_placement(game_id) do
    GenStateMachine.call(via_tuple(game_id), :set_ship_placement)
  end

  @doc """
  When making a guess, if it results in a win, the sate will switch to :game_over,
  and the state machine completes. Otherwise, if the guess does not error, then
  the state will switch to the other player, with the reply providing feedback
  necessary for the UI.
  """
  def guess_coordinate(game_id, col, row) do
    GenStateMachine.call(via_tuple(game_id), {:guess_coordinate, row, col})
  end

  ## SERVER CALLBACKS

  @impl true
  def init({game_id, p1_name}) do
    case Data.initialise(game_id, p1_name) do
      {:ok, data} ->
        {:ok, :initialised, data}
      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_event({:call, from}, {:add_player, p2_name}, :initialised, game_data) do
    case Data.add_second_player(game_data, p2_name) do
      {:ok, data} ->
        {:next_state, :players_setup, data, [{:reply, from, {:ok, data}}]}
      err ->
        {:keep_state_and_data, [{:reply, from, err}]}
    end
  end

  @impl true
  def handle_event({:call, from}, {:position_ship, player, type, dir, col, row}, :players_setup, game_data) do
    case Map.get(game_data, player).ships_to_place do
      [] ->
        {:keep_state_and_data, [{:reply, from, {:error, :all_player_ships_placed}}]}
      _available_ships ->
        case Data.place_ship(game_data, player, type, dir, col, row) do
          {:ok, data} ->
            {:keep_state, data, [{:reply, from, {:ok, data}}]}
          err ->
            {:keep_state_and_data, [{:reply, from, err}]}
        end
    end
  end

  @impl true
  def handle_event({:call, from}, :set_ship_placement, :players_setup, game_data) do
    case {game_data.player1.ships_to_place, game_data.player2.ships_to_place} do
      {[], []} ->
        {:next_state, :player1_turn, game_data, [{:reply, from, {:ok, game_data}}]}
      _ ->
        {:keep_state_and_data, [{:reply, from, {:error, :ship_placement_not_finalised}}]}
    end
  end

  @impl true
  def handle_event({:call, from}, {:guess_coordinate, col, row}, state, game_data) when state in [:player1_turn, :player2_turn] do
    case Data.make_guess(game_data, current_player(state), col, row) do
      {:ok, data, {_, ship_type, _, :win}} ->
        {:next_state, :game_over, data, [{:reply, from, {:ok, data, {:hit, ship_type, :sunk, :win}}}]}
      {:ok, data, guess_feedback} ->
        {:next_state, switch_player(state), data, [{:reply, from, {:ok, data, guess_feedback}}]}
      err ->
        {:keep_state_and_data, [{:reply, from, err}]}
    end
  end

  # Catch all to prevent errors - does nothing but return :error
  # if attempt made to enter impossible state.
  @impl true
  def handle_event({:call, from}, _event_content, _state, _data) do
    {:keep_state_and_data, [{:reply, from, {:error, :invalid_operation}}]}
  end

  defp current_player(:player1_turn), do: :player1
  defp current_player(:player2_turn), do: :player2

  defp switch_player(:player1_turn), do: :player2_turn
  defp switch_player(:player2_turn), do: :player1_turn


  defp via_tuple(game_id) do
    {:via, Registry, {Joust.Registry, game_id}}
  end
end
