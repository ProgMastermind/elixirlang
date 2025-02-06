defmodule Elixirlang.TokenTest do
  use ExUnit.Case
  alias Elixirlang.Token

  test "creates new token" do
    token = Token.new(:IDENT, "test")
    assert token.type == :IDENT
    assert token.literal == "test"
  end

  test "lookup_ident returns keyword token type for keywords" do
    assert Token.lookup_ident("def") == :DEF
    assert Token.lookup_ident("do") == :DO
    assert Token.lookup_ident("end") == :END
    assert Token.lookup_ident("if") == :IF
    assert Token.lookup_ident("else") == :ELSE
    assert Token.lookup_ident("true") == :TRUE
    assert Token.lookup_ident("false") == :FALSE
  end

  test "lookup_ident returns IDENT for non-keywords" do
    assert Token.lookup_ident("foo") == :IDENT
    assert Token.lookup_ident("bar") == :IDENT
    assert Token.lookup_ident("add") == :IDENT
    assert Token.lookup_ident("sum") == :IDENT
  end

  test "token types are atoms" do
    assert is_atom(Token.match())
    assert is_atom(Token.plus())
    assert is_atom(Token.minus())
    assert is_atom(Token.asterisk())
    assert is_atom(Token.slash())
    assert is_atom(Token.eq())
    assert is_atom(Token.not_eq())
  end

  test "delimiter tokens are defined" do
    assert Token.comma() == :COMMA
    assert Token.lparen() == :LPAREN
    assert Token.rparen() == :RPAREN
    assert Token.lbrace() == :LBRACE
    assert Token.rbrace() == :RBRACE
  end

  test "comparison operator tokens are defined" do
    assert Token.lt() == :LT
    assert Token.gt() == :GT
    assert Token.lte() == :LTE
    assert Token.gte() == :GTE
    assert Token.eq() == :EQ
    assert Token.not_eq() == :NOT_EQ
  end

  test "literal type tokens are defined" do
    assert Token.int() == :INT
    assert Token.string() == :STRING
    assert Token.atom() == :ATOM
  end

  test "special tokens are defined" do
    assert Token.illegal() == :ILLEGAL
    assert Token.eof() == :EOF
  end
end
