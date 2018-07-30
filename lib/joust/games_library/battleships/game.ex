defmodule Battleships.Game do
  @moduledoc """
  The FSM that controls the game state. Uses `gen_statem`.
  """
  use GenStateMachine

  require IEx

  alias Battleships.GameData, as: Data

  @type state ::
          :initialised
          | :players_setup
          | :game_active
          | :game_over

  ## CLIENT ACTIONS

  @doc """
  The state machine will initilise when a player starts it.

  At this point, the players still actually need to be added, which conflicts
  slightly with the above.

  The reason for not initialising with the first player is that the `init`
  returns `{:ok, pid}`, whereas, for the UI, it is preferable to return `{:ok, data}`.

  So the game _manager_ needs to match in the `{:ok, pid}` to confirm startup,
  then immediately run `add_player/2` with the first player's name.
  This should provide insurance against [invalid] games being created that
  have no players.

  The data in the state machine is initialised with a new Player struct containing
  the player who initialised the game, and the state is set to :initialised
  """
  def start_link(game_id) do
    GenStateMachine.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  @doc """
  Adding another player should transition the state to `players_set` which is
  a bad name but it'll do for the minute (REVIEW possibly `players_ready`?)
  """
  def add_player(game_id, name) do
    GenStateMachine.call(via_tuple(game_id), {:add_player, name})
  end


  def position_ship(game_id, player_number, type, dir, col, row) do
    GenStateMachine.call(via_tuple(game_id), {:position_ship, player_number, type, dir, col, row})
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
  def init(game_id) do
    case Data.initialise(game_id) do
      {:ok, data} ->
        {:ok, :initialised, data}
      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_event({:call, from}, {:add_player, name}, :initialised, game_data) do
    case Data.add_player(game_data, name) do
      {:ok, %{registered_players: rps, max_players: mps} = data} when rps < mps ->
        {:keep_state, data, [{:reply, from, {:ok, data}}]}
      {:ok, data} ->
        {:next_state, :players_setup, data, [{:reply, from, {:ok, data}}]}
      err ->
        {:keep_state_and_data, [{:reply, from, err}]}
    end
  end

  @impl true
  def handle_event({:call, from}, {:position_ship, player_number, type, dir, col, row}, :players_setup, game_data) do
    case get_in(game_data, [:player, player_number, :ships_to_place]) do
      [] ->
        {:keep_state_and_data, [{:reply, from, {:error, :all_player_ships_placed}}]}
      _available_ships ->
        case Data.place_ship(game_data, player_number, type, dir, col, row) do
          {:ok, data} ->
            {:keep_state, data, [{:reply, from, {:ok, data}}]}
          err ->
            {:keep_state_and_data, [{:reply, from, err}]}
        end
    end
  end

  @impl true
  def handle_event({:call, from}, :set_ship_placement, :players_setup, game_data) do
    players = Map.get(game_data, :players)
    case Enum.all?(players, fn %{ships_to_place: stp} -> Enum.empty?(stp) end) do
      true ->
        {:next_state, :game_active, game_data, [{:reply, from, {:ok, game_data}}]}
      false ->
        {:keep_state_and_data, [{:reply, from, {:error, :ship_placement_not_finalised}}]}
    end
  end

  @impl true
  # FIXME the correct/incorect guesses are going in or coming out as wrong way round:
  # should be {x, y} but they're {y, x}. Investigate where this error is
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
