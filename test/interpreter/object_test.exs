defmodule Elixirlang.ObjectTest do
  use ExUnit.Case
  alias Elixirlang.Object

  describe "Integer" do
    test "creates new integer object" do
      int = Object.Integer.new(5)
      assert int.value == 5
      assert Object.type(int) == :INTEGER
    end
  end
end
