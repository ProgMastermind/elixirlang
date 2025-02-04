defmodule Elixirlang.LexerTest do
  use ExUnit.Case
  alias Elixirlang.{Lexer, Token}

  test "next_token handles single character tokens" do
    input = "=+(){},;"

    expected_tokens = [
      {Token.assign(), "="},
      {Token.plus(), "+"},
      {Token.lparen(), "("},
      {Token.rparen(), ")"},
      {Token.lbrace(), "{"},
      {Token.rbrace(), "}"},
      {Token.comma(), ","},
      {Token.semicolon(), ";"},
      {Token.eof(), ""}
    ]

    verify_tokens(input, expected_tokens)
  end

  test "next_token handles a complete program" do
    input = """
    def add(x, y) do
      x + y;
    end
    """

    expected_tokens = [
      {Token.def_(), "def"},
      {Token.ident(), "add"},
      {Token.lparen(), "("},
      {Token.ident(), "x"},
      {Token.comma(), ","},
      {Token.ident(), "y"},
      {Token.rparen(), ")"},
      {Token.do_(), "do"},
      {Token.ident(), "x"},
      {Token.plus(), "+"},
      {Token.ident(), "y"},
      {Token.semicolon(), ";"},
      {Token.end_(), "end"},
      {Token.eof(), ""}
    ]

    verify_tokens(input, expected_tokens)
  end

  test "next_token handles numbers" do
    input = "5 + 10;"

    expected_tokens = [
      {Token.int(), "5"},
      {Token.plus(), "+"},
      {Token.int(), "10"},
      {Token.semicolon(), ";"},
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
