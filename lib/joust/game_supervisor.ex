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
    game_id = Joust.Utils.generate_id()

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
      :start => {module_delegator(game_type), :start_link, [game_id]},
      :restart => :transient,
      :shutdown => 5000
    }

    DynamicSupervisor.start_child(__MODULE__, game_spec)
  end

  @doc """
  Given an atom identifier, for example :battleships, generate a module
  identifier that can be used to start the main Game.start_link process

  ## Example

      iex> module_delegator(:battleships)
      Battleships.Game
      iex> module_delegator(:noughts_and_crosses)
      NoughtsAndCrosses.Game
  """
  def module_delegator(atom_identifier, game_submodule \\ Game) do
    atom_identifier
    |> Joust.Utils.atom_to_modname()
    |> Module.concat(game_submodule)
  end
end
