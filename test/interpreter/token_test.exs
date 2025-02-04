defmodule Elixirlang.TokenTest do
  use ExUnit.Case
  alias Elixirlang.Token

  test "creates new token" do
    token = Token.new(:IDENT, "test")
    assert token.type == :IDENT
    assert token.literal == "test"
  end

  test "lookup_ident returns keyword token type for keywords" do
    assert Token.lookup_ident("def") == Token.def_()
    assert Token.lookup_ident("do") == Token.do_()
    assert Token.lookup_ident("end") == Token.end_()
  end

  test "lookup_ident returns IDENT for non-keywords" do
    assert Token.lookup_ident("foo") == Token.ident()
    assert Token.lookup_ident("bar") == Token.ident()
  end
end
