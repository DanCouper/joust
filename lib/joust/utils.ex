defmodule Joust.Utils do
  @moduledoc """
  Useful functions
  """

  @doc """
  Generate a 64-bit pseudo-random ID. Unless a UUID is vital; this should do,
  collisions are extremely unlikely.

  NOTE the number passed to :rand.uniform is not arbitrary, it is
  the number of different values expressible in 32 bits,
  see: http://googology.wikia.com/wiki/4294967296
  """
  @spec generate_id() :: String.t()
  def generate_id do
    Integer.to_string(:rand.uniform(4294967296), 32) <> Integer.to_string(:rand.uniform(4294967296), 32)
  end

  defmodule TurnBuffer do
    @moduledoc """
    A tiny circular queue of player IDs to allow switching
    turns. Once filled with all the current players,
    `get_current` will return the current player ID, and
    `next` will rotate the queue, moving the current player
    to the rear of the queue.
    """

    @doc """
    Initialise a new turn buffer. Either start empty,
    or with a single player ID, or with a complete
    list of player IDs.

    ## Example

        iex> TurnBuffer.new()
        {[], []}
        iex> TurnBuffer.new("21KRPNVQG2LNV")
        {["21KRPNVQG2LNV"], []}
        iex> TurnBuffer.new(["21KRPNVQG2LNV", "3C8OM2822HJFO6", "F7G5762JSSI6I"])
        {["F7G5762JSSI6I"], ["21KRPNVQG2LNV", "3C8OM2822HJFO6"]}
    """
    @opaque buffer :: :queue.t()

    @spec new :: buffer()
    @spec new(String.t()) :: buffer()
    @spec new([String.t()]) :: buffer()
    def new(), do: :queue.new()
    def new(id) when is_binary(id), do: :queue.from_list([id])
    # FIXME constrain the ids to being binaries
    def new(ids) when is_list(ids), do: :queue.from_list(ids)

    @doc """
    Add an ID to the _rear_ of the queue. The first player will
    also be the first to be added to the buffer, and the second
    will be the second and so on. Therefore when the queue is
    fully populated, the head should be the first player , and the
    tail should end with the last player.

    ## Example

        iex> buffer = TurnBuffer.new()
        iex> buffer = TurnBuffer.add(buffer, "21KRPNVQG2LNV")
        {["21KRPNVQG2LNV"], []}
        iex> buffer = TurnBuffer.add(buffer, "3C8OM2822HJFO6")
        {["3C8OM2822HJFO6"], ["21KRPNVQG2LNV"]}
        iex> buffer = TurnBuffer.add(buffer, "F7G5762JSSI6I")
        {["F7G5762JSSI6I", "3C8OM2822HJFO6"], ["21KRPNVQG2LNV"]}
    """
    @spec add(buffer(), String.t()) :: :queue.t()
    def add(buffer, id), do: :queue.in(id, buffer)


    @doc """
    Check the current player ID

    ## Example

        iex> TurnBuffer.new(["21KRPNVQG2LNV", "3C8OM2822HJFO6", "F7G5762JSSI6I"])
        {["F7G5762JSSI6I"], ["21KRPNVQG2LNV", "3C8OM2822HJFO6"]}
        iex> TurnBuffer.get_current(buffer)
        "21KRPNVQG2LNV"
    """
    @spec get_current(buffer()) :: String.t()
    def get_current(buffer) do
      {_, id} = :queue.peek(buffer)
      id
    end

    @doc """
    Switch to the next player. This is done by pulling the current
    player ID from the buffer (the head of the queue), and adding it
    to the rear.

    ## Example

        iex> TurnBuffer.new(["21KRPNVQG2LNV", "3C8OM2822HJFO6", "F7G5762JSSI6I"])
        {["F7G5762JSSI6I"], ["21KRPNVQG2LNV", "3C8OM2822HJFO6"]}
        iex> TurnBuffer.get_current(buffer)
        "21KRPNVQG2LNV"
        iex> buffer = TurnBuffer.next(buffer)
        {["21KRPNVQG2LNV", "F7G5762JSSI6I"], ["3C8OM2822HJFO6"]}
        iex> TurnBuffer.get_current(buffer)
        "3C8OM2822HJFO6"
        iex> buffer = TurnBuffer.next(buffer)
        {["3C8OM2822HJFO6", "21KRPNVQG2LNV"], ["F7G5762JSSI6I"]}
        iex> TurnBuffer.get_current(buffer)
        "F7G5762JSSI6I"
        iex> buffer = TurnBuffer.next(buffer)
        {["F7G5762JSSI6I", "3C8OM2822HJFO6"], ["21KRPNVQG2LNV"]}
        iex> TurnBuffer.get_current(buffer)
        "21KRPNVQG2LNV"
    """
    @spec next(buffer()) :: buffer()
    def next(buffer) do
      {{_, id}, buffer} = :queue.out(buffer)
      :queue.in(id, buffer)
    end
  end
end
