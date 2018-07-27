defmodule Joust.Games.Supervisor do
  @moduledoc """
  The supervisor that allows spawning of games. Spawn as many
  as you fancy!
  """

  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    opts = [
      strategy: :one_for_one
    ]

    DynamicSupervisor.init(opts)
  end

  def start_game(game_type) do
    game_id = Joust.Utils.generate_id()

    case start_game_process(game_type, game_id) do
      {:ok, _pid} ->
        {:ok, game_id}
      {:error, {:undef, _}} ->
        {:error, :nonexistant_game_type}
      err ->
        err
    end
  end

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
  """
  def module_delegator(atom_identifier) do
    game_identifier = atom_identifier |> to_string() |> String.capitalize()
    Module.concat(game_identifier, Game)
  end
end
