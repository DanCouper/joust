defmodule ConnectFour.Game do
  @moduledoc """
  The FSM that controls the game state. Uses `gen_statem`.
  """
  use GenStateMachine

  require IEx # NOTE used for `pry/0` during development

  alias ConnectFour.GameData, as: Data
end
