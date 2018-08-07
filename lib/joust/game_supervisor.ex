defmodule Joust.GameSupervisor do
  @moduledoc """
  The supervisor that allows spawning of games. Spawn as many
  as you fancy!
  """

  require Logger

  use DynamicSupervisor

  @doc false
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    opts = [
      strategy: :one_for_one
    ]

    DynamicSupervisor.init(opts)
  end

  @doc """
  Given a game type, spawn a game process with the game struct as the state.
  Return value is the game's ID, allowing lookup in the registry, rather than
  the game state itself
  """
  @spec initialise_new_game(atom()) :: {:ok, String.t()} | {:error, :nonexistant_game_type}
  def initialise_new_game(game_type) do
    game_id = Joust.Utils.generate_id!()

    case start_game_process(game_type, game_id) do
      {:ok, _pid} ->
        Logger.info(
          "Game of type #{Atom.to_string(game_type)} started, registered under id #{game_id}."
        )

        {:ok, game_id}

      {:error, {:undef, _}} ->
        {:error, :nonexistant_game_type}

      err ->
        err
    end
  end

  # Internal logic for spawning a game: the given atom has to be converted to a module name
  # and then the game can be spawned and registered using the generated ID.
  defp start_game_process(game_type, game_id) do
    game_spec = %{
      :id => __MODULE__,
      :start => {Utils.module_delegator(game_type), :start_link, [game_id]},
      :restart => :transient,
      :shutdown => 5000
    }

    DynamicSupervisor.start_child(__MODULE__, game_spec)
  end

  @doc """
  TODO  fill this out. On unscheduled termination, a game should
  reinitialise with the state present at point of failure.
  This should be pulled from an ETS store, and `start_link`
  will cause the init function to return with the state/data
  pulled from the store rather than the standard return.
  """
  def recover_game(game_id) do
    true
  end
end
