defmodule Elixirlang.LexerTest do
  use ExUnit.Case
  alias Elixirlang.{Lexer, Token}

  test "next_token handles single character tokens" do
    input = "=+(){}"

    expected_tokens = [
      {Token.match(), "="},
      {Token.plus(), "+"},
      {Token.lparen(), "("},
      {Token.rparen(), ")"},
      {Token.lbrace(), "{"},
      {Token.rbrace(), "}"},
      {Token.eof(), ""}
    ]

    verify_tokens(input, expected_tokens)
  end

  test "next_token handles comparison operators" do
    input = "== != < > <= >="

    expected_tokens = [
      {Token.eq(), "=="},
      {Token.not_eq(), "!="},
      {Token.lt(), "<"},
      {Token.gt(), ">"},
      {Token.lte(), "<="},
      {Token.gte(), ">="},
      {Token.eof(), ""}
    ]

    verify_tokens(input, expected_tokens)
  end

  test "next_token handles arithmetic operators" do
    input = "+ - * / ="

    expected_tokens = [
      {Token.plus(), "+"},
      {Token.minus(), "-"},
      {Token.asterisk(), "*"},
      {Token.slash(), "/"},
      {Token.match(), "="},
      {Token.eof(), ""}
    ]

    verify_tokens(input, expected_tokens)
  end

  test "next_token handles keywords" do
    input = """
    def if else true false do end
    """

    expected_tokens = [
      {Token.def_(), "def"},
      {Token.if_(), "if"},
      {Token.else_(), "else"},
      {Token.true_(), "true"},
      {Token.false_(), "false"},
      {Token.do_(), "do"},
      {Token.end_(), "end"},
      {Token.eof(), ""}
    ]

    verify_tokens(input, expected_tokens)
  end

  test "next_token handles string literals" do
    input = ~s("hello world" "test")

    expected_tokens = [
      {Token.string(), "hello world"},
      {Token.string(), "test"},
      {Token.eof(), ""}
    ]

    verify_tokens(input, expected_tokens)
  end

  test "next_token handles atoms" do
    input = ":atom :test"

    expected_tokens = [
      {Token.atom(), "atom"},
      {Token.atom(), "test"},
      {Token.eof(), ""}
    ]

    verify_tokens(input, expected_tokens)
  end

  test "next_token handles comments" do
    input = """
    # this is a comment
    def add(x) # inline comment
      x + 1 # another comment
    end
    """

    expected_tokens = [
      {Token.def_(), "def"},
      {Token.ident(), "add"},
      {Token.lparen(), "("},
      {Token.ident(), "x"},
      {Token.rparen(), ")"},
      {Token.ident(), "x"},
      {Token.plus(), "+"},
      {Token.int(), "1"},
      {Token.end_(), "end"},
      {Token.eof(), ""}
    ]

    verify_tokens(input, expected_tokens)
  end

  test "next_token handles identifiers and numbers" do
    input = """
    x = 5
    y = 10
    add = x + y
    """

    expected_tokens = [
      {Token.ident(), "x"},
      {Token.match(), "="},
      {Token.int(), "5"},
      {Token.ident(), "y"},
      {Token.match(), "="},
      {Token.int(), "10"},
      {Token.ident(), "add"},
      {Token.match(), "="},
      {Token.ident(), "x"},
      {Token.plus(), "+"},
      {Token.ident(), "y"},
      {Token.eof(), ""}
    ]

    verify_tokens(input, expected_tokens)
  end

  test "next_token handles complex expressions" do
    input = """
    def sum(a, b) do
      result = a + b
      result
    end
    """

    expected_tokens = [
      {Token.def_(), "def"},
      {Token.ident(), "sum"},
      {Token.lparen(), "("},
      {Token.ident(), "a"},
      {Token.comma(), ","},
      {Token.ident(), "b"},
      {Token.rparen(), ")"},
      {Token.do_(), "do"},
      {Token.ident(), "result"},
      {Token.match(), "="},
      {Token.ident(), "a"},
      {Token.plus(), "+"},
      {Token.ident(), "b"},
      {Token.ident(), "result"},
      {Token.end_(), "end"},
      {Token.eof(), ""}
    ]

    verify_tokens(input, expected_tokens)
  end

  defp verify_tokens(input, expected_tokens) do
    lexer = Lexer.new(input)
    tokens = collect_tokens(lexer)
    assert_tokens(tokens, expected_tokens)
  end

  defp collect_tokens(lexer) do
    {token, new_lexer} = Lexer.next_token(lexer)

    if token.type == :EOF do
      [token]
    else
      [token | collect_tokens(new_lexer)]
    end
  end

  defp assert_tokens(actual_tokens, expected_tokens) do
    actual_pairs = Enum.map(actual_tokens, &{&1.type, &1.literal})
    assert actual_pairs == expected_tokens
  end
end
