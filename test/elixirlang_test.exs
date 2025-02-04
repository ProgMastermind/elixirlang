defmodule ElixirlangTest do
  use ExUnit.Case
  doctest Elixirlang

  test "greets the world" do
    assert Elixirlang.hello() == :world
  end
end
