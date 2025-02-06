defmodule Elixirlang.Parser do
  alias Elixirlang.{Token, Lexer, AST}

  @precedences %{
    :EQ => :EQUALS,
    :NOT_EQ => :EQUALS,
    :LT => :LESSGREATER,
    :GT => :LESSGREATER,
    :LTE => :LESSGREATER,
    :GTE => :LESSGREATER,
    :PLUS => :SUM,
    :MINUS => :SUM,
    :SLASH => :PRODUCT,
    :ASTERISK => :PRODUCT
  }

  @precedence_values %{
    :LOWEST => 1,
    :EQUALS => 2,
    :LESSGREATER => 3,
    :SUM => 4,
    :PRODUCT => 5,
    :PREFIX => 6,
    :CALL => 7
  }

  defstruct lexer: nil,
            current_token: nil,
            peek_token: nil,
            errors: []

  def new(lexer) do
    parser = %__MODULE__{lexer: lexer}

    parser
    |> next_token()
    |> next_token()
  end

  def parse_program(parser) do
    program = %AST.Program{statements: []}
    parse_program_statements(parser, program.statements)
  end

  defp parse_program_statements(parser, statements) do
    if parser.current_token.type == Token.eof() do
      {%AST.Program{statements: Enum.reverse(statements)}, parser}
    else
      case parse_statement(parser) do
        {statement, new_parser} ->
          parse_program_statements(
            next_token(new_parser),
            [statement | statements]
          )
      end
    end
  end

  defp parse_statement(parser) do
    parse_expression_statement(parser)
  end

  defp parse_expression_statement(parser) do
    token = parser.current_token
    {expression, new_parser} = parse_expression(parser, :LOWEST)
    {%AST.ExpressionStatement{token: token, expression: expression}, new_parser}
  end

  defp parse_expression(parser, precedence) do
    {left, new_parser} =
      case parser.current_token.type do
        :INT -> parse_integer_literal(parser)
        :BANG -> parse_prefix_expression(parser)
        :MINUS -> parse_prefix_expression(parser)
        :PLUS -> parse_prefix_expression(parser)
        :TRUE -> parse_boolean_literal(parser)
        :FALSE -> parse_boolean_literal(parser)
        _ -> {nil, parser}
      end

    parse_expression_continued(new_parser, left, @precedence_values[precedence])
  end

  defp parse_expression_continued(parser, left, precedence) do
    cond do
      left == nil ->
        {nil, parser}

      precedence >= peek_precedence_value(parser) ->
        {left, parser}

      true ->
        case infix_parse_fn(parser.peek_token.type) do
          nil ->
            {left, parser}

          infix_fn ->
            parser = next_token(parser)
            {new_left, new_parser} = infix_fn.(parser, left)
            parse_expression_continued(new_parser, new_left, precedence)
        end
    end
  end

  defp parse_integer_literal(parser) do
    {%AST.IntegerLiteral{
       token: parser.current_token,
       value: String.to_integer(parser.current_token.literal)
     }, parser}
  end

  defp parse_boolean_literal(parser) do
    {%AST.BooleanLiteral{
       token: parser.current_token,
       value: parser.current_token.type == :TRUE
     }, parser}
  end

  defp parse_prefix_expression(parser) do
    token = parser.current_token
    operator = parser.current_token.literal

    parser = next_token(parser)
    {right, new_parser} = parse_expression(parser, :PREFIX)

    {%AST.PrefixExpression{
       token: token,
       operator: operator,
       right: right
     }, new_parser}
  end

  defp parse_infix_expression(parser, left) do
    token = parser.current_token
    operator = parser.current_token.literal
    precedence = current_precedence_value(parser)

    parser = next_token(parser)
    {right, new_parser} = parse_expression(parser, get_precedence_name(precedence))

    {%AST.InfixExpression{
       token: token,
       left: left,
       operator: operator,
       right: right
     }, new_parser}
  end

  defp infix_parse_fn(token_type)
       when token_type in [:PLUS, :MINUS, :SLASH, :ASTERISK, :EQ, :NOT_EQ, :LT, :GT, :LTE, :GTE] do
    &parse_infix_expression/2
  end

  defp infix_parse_fn(_), do: nil

  defp peek_precedence_value(parser) do
    precedence = Map.get(@precedences, parser.peek_token.type, :LOWEST)
    @precedence_values[precedence]
  end

  defp current_precedence_value(parser) do
    precedence = Map.get(@precedences, parser.current_token.type, :LOWEST)
    @precedence_values[precedence]
  end

  defp get_precedence_name(value) do
    Enum.find(@precedence_values, fn {_k, v} -> v == value end) |> elem(0)
  end

  defp next_token(parser) do
    %{
      parser
      | current_token: parser.peek_token,
        peek_token: elem(Lexer.next_token(parser.lexer), 0),
        lexer: elem(Lexer.next_token(parser.lexer), 1)
    }
  end
end
