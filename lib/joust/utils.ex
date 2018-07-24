defmodule Joust.Utils do
  @moduledoc """
  Useful functions
  """

  @doc """
  Generate a 64-bit pseudo-random ID. Unless a UUID is vital; this should do,
  collisions are extremely unlikely.
  """
  @spec generate_id() :: String.t()
  def generate_id do
    Integer.to_string(:rand.uniform(4294967296), 32) <> Integer.to_string(:rand.uniform(4294967296), 32)
  end
end
