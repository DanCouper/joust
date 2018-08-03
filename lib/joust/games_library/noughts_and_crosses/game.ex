defmodule NoughtsAndCrosses.Game do
  @moduledoc """
  The FSM that controls the game state. Uses `gen_statem`.
  """
  use GenStateMachine

  require IEx # NOTE used for `pry/0` during development

  alias NoughtsAndCrosses.GameData, as: Data
  alias Joust.Utils


  @type state ::
    :initialised
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
    GenStateMachine.start_link(__MODULE__, game_id, name: Utils.via_tuple(game_id))
  end

  @doc """
  Adding another player should transition the state to `players_set` which is
  a bad name but it'll do for the minute (REVIEW possibly `players_ready`?)
  """
  def add_player(game_id, name) do
    GenStateMachine.call(Utils.via_tuple(game_id), {:add_player, name})
  end

  def take_move(game_id, board, cell) do
    GenStateMachine.call(Utils.via_tuple(game_id), {:take_move, board, cell})
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
        {:next_state, :game_active, data, [{:reply, from, {:ok, data}}]}
      err ->
        {:keep_state_and_data, [{:reply, from, err}]}
    end
  end

  @impl true
  def handle_event({:call, from}, {:take_move, board, cell}, :game_active, game_data) do
    case Data.take_move(game_data, board, cell) do
      {:ok, data, {:no_win}} ->
        {:keep_state, data, [{:reply, from, {:ok, data, {:no_win}}}]}
      {:ok, data, {end_status}} ->
        {:next_state, :game_over, data, [{:reply, from, {:ok, data, {end_status}}}]}
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
end
