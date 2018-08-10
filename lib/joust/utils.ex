defmodule Joust.Utils do
  @moduledoc """
  Generic utility functions.
  """

  @doc """
  Generate a 64-bit pseudo-random ID. Unless a UUID is vital; this should do,
  collisions are extremely unlikely.

  NOTE the number passed to :rand.uniform is not arbitrary, it is
  the number of different values expressible in 32 bits,
  see: http://googology.wikia.com/wiki/4294967296
  """
  @spec generate_id!() :: String.t()
  def generate_id! do
    Integer.to_string(:rand.uniform(4_294_967_296), 32) <>
      Integer.to_string(:rand.uniform(4_294_967_296), 32)
  end

  @doc """
  Convert an Elixir atom to the string version of a module name.

  ## Example

      iex> atom_to_modname(:foo)
      "Foo"
      iex> atom_to_modname(:foo_bar)
      "FooBar"
  """
  @spec atom_to_modname(atom()) :: String.t()
  def atom_to_modname(atom_identifier) do
    atom_identifier
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join()
  end

  @doc """
  Given an atom identifier, for example :battleships, generate a module
  identifier that can be used to, for example, start the main Game.start_link process

  ## Example

      iex> module_delegator(:battleships)
      Battleships.Game
      iex> module_delegator(:noughts_and_crosses)
      NoughtsAndCrosses.Game
  """
  @spec module_delegator(atom(), module()) :: module()
  def module_delegator(atom_identifier, submodule \\ Game) do
    atom_identifier
    |> atom_to_modname()
    |> Module.concat(submodule)
  end

  @doc """
  Utility function for accessing the registry using a string ID. Used anywhere
  a PID would be necessary when calling GenServers.

  REVIEW what if I want to bypass the registry when testing? Use this as a
  facade (possibly revert to `global`?).
  """
  @spec via_tuple(String.t()) :: {:via, Registry, {Joust.Registry, String.t()}}
  def via_tuple(id) do
    {:via, Registry, {Joust.Registry, id}}
  end
end
