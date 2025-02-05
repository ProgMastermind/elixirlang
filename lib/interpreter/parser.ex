defmodule Elixirlang.Parser do
  alias Elixirlang.{Token, Lexer, AST}

  defstruct lexer: nil,
            current_token: nil,
            peek_token: nil,
            errors: []

  def new(lexer) do
    parser = %__MODULE__{lexer: lexer}
    # Read two tokens to set current_token and peek_token
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

    new_parser =
      if peek_token_is(new_parser, Token.semicolon()) do
        next_token(new_parser)
      else
        new_parser
      end

    {%AST.ExpressionStatement{token: token, expression: expression}, new_parser}
  end

  defp parse_expression(parser, _precedence) do
    case parser.current_token.type do
      :INT -> parse_integer_literal(parser)
      _ -> {nil, parser}
    end
  end

  defp parse_integer_literal(parser) do
    {%AST.IntegerLiteral{
       token: parser.current_token,
       value: String.to_integer(parser.current_token.literal)
     }, parser}
  end

  defp next_token(parser) do
    %{
      parser
      | current_token: parser.peek_token,
        peek_token: elem(Lexer.next_token(parser.lexer), 0),
        lexer: elem(Lexer.next_token(parser.lexer), 1)
    }
  end

  defp peek_token_is(parser, token_type) do
    parser.peek_token.type == token_type
  end
end
