defmodule JoustTest do
  use ExUnit.Case
  doctest Joust

  test "greets the world" do
    assert Joust.hello() == :world
  end
end
