defmodule Joust.GamesSupervisor do
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

  def start_game(start_player_name) do
    game_spec = %{
      :id => __MODULE__,
      :start => {Battleships.GameStatem, :start_link, [Joust.Utils.generate_id(), start_player_name]},
      :restart => :transient,
      :shutdown => 5000
    }

    DynamicSupervisor.start_child(__MODULE__, game_spec)
  end
end
