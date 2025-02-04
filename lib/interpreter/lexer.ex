defmodule Elixirlang.Lexer do
  alias Elixirlang.Token

  defstruct input: "", position: 0, read_position: 0, ch: nil

  def new(input) do
    lexer = %__MODULE__{input: input}
    read_char(lexer)
  end

  def next_token(%__MODULE__{} = lexer) do
    lexer = skip_whitespace(lexer)

    {token, new_lexer} =
      case lexer.ch do
        ?= ->
          {Token.new(Token.assign(), "="), read_char(lexer)}

        ?+ ->
          {Token.new(Token.plus(), "+"), read_char(lexer)}

        ?- ->
          {Token.new(Token.minus(), "-"), read_char(lexer)}

        ?! ->
          {Token.new(Token.bang(), "!"), read_char(lexer)}

        ?* ->
          {Token.new(Token.asterisk(), "*"), read_char(lexer)}

        ?/ ->
          {Token.new(Token.slash(), "/"), read_char(lexer)}

        ?, ->
          {Token.new(Token.comma(), ","), read_char(lexer)}

        ?; ->
          {Token.new(Token.semicolon(), ";"), read_char(lexer)}

        ?( ->
          {Token.new(Token.lparen(), "("), read_char(lexer)}

        ?) ->
          {Token.new(Token.rparen(), ")"), read_char(lexer)}

        ?{ ->
          {Token.new(Token.lbrace(), "{"), read_char(lexer)}

        ?} ->
          {Token.new(Token.rbrace(), "}"), read_char(lexer)}

        nil ->
          {Token.new(Token.eof(), ""), lexer}

        ch ->
          cond do
            letter?(ch) ->
              {identifier, l} = read_identifier(lexer)
              token_type = Token.lookup_ident(identifier)
              {Token.new(token_type, identifier), l}

            digit?(ch) ->
              {number, l} = read_number(lexer)
              {Token.new(Token.int(), number), l}

            true ->
              {Token.new(Token.illegal(), <<ch>>), read_char(lexer)}
          end
      end

    {token, new_lexer}
  end

  defp read_char(%__MODULE__{} = lexer) do
    ch =
      if lexer.read_position >= String.length(lexer.input) do
        nil
      else
        String.at(lexer.input, lexer.read_position)
        |> case do
          nil -> nil
          str -> String.to_charlist(str) |> hd()
        end
      end

    %{
      lexer
      | ch: ch,
        position: lexer.read_position,
        read_position: lexer.read_position + 1
    }
  end

  defp read_identifier(%__MODULE__{} = lexer) do
    position = lexer.position

    lexer = read_while(lexer, &letter?/1)

    identifier =
      String.slice(lexer.input, position, lexer.position - position)

    {identifier, lexer}
  end

  defp read_number(%__MODULE__{} = lexer) do
    position = lexer.position

    lexer = read_while(lexer, &digit?/1)

    number =
      String.slice(lexer.input, position, lexer.position - position)

    {number, lexer}
  end

  defp read_while(%__MODULE__{} = lexer, condition) do
    if lexer.ch && condition.(lexer.ch) do
      lexer
      |> read_char()
      |> read_while(condition)
    else
      lexer
    end
  end

  defp skip_whitespace(%__MODULE__{} = lexer) do
    if whitespace?(lexer.ch) do
      lexer
      |> read_char()
      |> skip_whitespace()
    else
      lexer
    end
  end

  defp letter?(ch) when ch in ?a..?z, do: true
  defp letter?(ch) when ch in ?A..?Z, do: true
  defp letter?(?_), do: true
  defp letter?(_), do: false

  defp digit?(ch) when ch in ?0..?9, do: true
  defp digit?(_), do: false

  defp whitespace?(ch) when ch in [?\s, ?\t, ?\n, ?\r], do: true
  defp whitespace?(_), do: false
end
