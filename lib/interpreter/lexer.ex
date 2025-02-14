defmodule Elixirlang.Lexer do
  @moduledoc """
  Converts source code into tokens.

  The lexer is the first stage of interpretation, breaking down raw input text
  into meaningful tokens that can be processed by the parser.

  Example:
      iex> Lexer.new("5 + 3")
      #=> Tokens: [INT(5), PLUS, INT(3)]
  """

  alias Elixirlang.Token

  defstruct input: "", position: 0, read_position: 0, ch: nil

  @doc """
  Creates a new lexer instance with the given input string.
  """
  def new(input) do
    lexer = %__MODULE__{input: input}
    read_char(lexer)
  end

  @doc """
  Reads the next token from the input stream.
  Returns a tuple of {token, new_lexer_state}.
  """
  def next_token(%__MODULE__{} = lexer) do
    lexer = skip_whitespace(lexer)

    {token, new_lexer} =
      case lexer.ch do
        ?= ->
          if peek_char(lexer) == ?= do
            {Token.new(Token.eq(), "=="), read_char(read_char(lexer))}
          else
            {Token.new(Token.match(), "="), read_char(lexer)}
          end

        ?! ->
          if peek_char(lexer) == ?= do
            {Token.new(Token.not_eq(), "!="), read_char(read_char(lexer))}
          else
            {Token.new(Token.bang(), "!"), read_char(lexer)}
          end

        ?< ->
          cond do
            peek_char(lexer) == ?> ->
              {Token.new(Token.concat(), "<>"), read_char(read_char(lexer))}

            peek_char(lexer) == ?= ->
              {Token.new(Token.lte(), "<="), read_char(read_char(lexer))}

            true ->
              {Token.new(Token.lt(), "<"), read_char(lexer)}
          end

        ?> ->
          if peek_char(lexer) == ?= do
            {Token.new(Token.gte(), ">="), read_char(read_char(lexer))}
          else
            {Token.new(Token.gt(), ">"), read_char(lexer)}
          end

        ?" ->
          {string, lexer} = read_string(lexer)
          {Token.new(Token.string(), string), read_char(lexer)}

        ?: ->
          {atom, lexer} = read_atom(lexer)
          {Token.new(Token.atom(), atom), lexer}

        ?+ ->
          {Token.new(Token.plus(), "+"), read_char(lexer)}

        ?- ->
          {Token.new(Token.minus(), "-"), read_char(lexer)}

        ?* ->
          {Token.new(Token.asterisk(), "*"), read_char(lexer)}

        ?/ ->
          {Token.new(Token.slash(), "/"), read_char(lexer)}

        ?, ->
          {Token.new(Token.comma(), ","), read_char(lexer)}

        ?( ->
          {Token.new(Token.lparen(), "("), read_char(lexer)}

        ?) ->
          {Token.new(Token.rparen(), ")"), read_char(lexer)}

        ?{ ->
          {Token.new(Token.lbrace(), "{"), read_char(lexer)}

        ?} ->
          {Token.new(Token.rbrace(), "}"), read_char(lexer)}

        ?[ ->
          {Token.new(Token.lbracket(), "["), read_char(lexer)}

        ?] ->
          {Token.new(Token.rbracket(), "]"), read_char(lexer)}

        ?| ->
          if peek_char(lexer) == ?> do
            {Token.new(Token.pipe(), "|>"), read_char(read_char(lexer))}
          else
            {Token.new(Token.illegal(), "|"), read_char(lexer)}
          end

        ?# ->
          lexer = skip_comment(lexer)
          next_token(lexer)

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

  defp peek_char(%__MODULE__{} = lexer) do
    if lexer.read_position >= String.length(lexer.input) do
      nil
    else
      String.at(lexer.input, lexer.read_position)
      |> case do
        nil -> nil
        str -> String.to_charlist(str) |> hd()
      end
    end
  end

  defp read_identifier(%__MODULE__{} = lexer) do
    position = lexer.position
    lexer = read_while(lexer, &letter?/1)
    identifier = String.slice(lexer.input, position, lexer.position - position)
    {identifier, lexer}
  end

  defp read_number(%__MODULE__{} = lexer) do
    position = lexer.position
    lexer = read_while(lexer, &digit?/1)
    number = String.slice(lexer.input, position, lexer.position - position)
    {number, lexer}
  end

  defp read_string(%__MODULE__{} = lexer) do
    position = lexer.position + 1
    lexer = read_char(lexer)
    lexer = read_while(lexer, fn ch -> ch != ?" end)
    string = String.slice(lexer.input, position, lexer.position - position)
    {string, lexer}
  end

  defp read_atom(%__MODULE__{} = lexer) do
    lexer = read_char(lexer)
    position = lexer.position
    lexer = read_while(lexer, &letter?/1)
    atom = String.slice(lexer.input, position, lexer.position - position)
    {atom, lexer}
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

  defp skip_comment(%__MODULE__{} = lexer) do
    lexer = read_while(lexer, fn ch -> ch != ?\n end)
    read_char(lexer)
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
