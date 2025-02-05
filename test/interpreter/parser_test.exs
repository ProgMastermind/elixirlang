defmodule Elixirlang.ParserTest do
  use ExUnit.Case
  alias Elixirlang.{Lexer, Parser, AST}

  test "parses integer literals" do
    input = "5;"
    program = parse_program(input)

    assert length(program.statements) == 1
    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.IntegerLiteral{value: 5} = stmt.expression
  end

  defp parse_program(input) do
    lexer = Lexer.new(input)
    parser = Parser.new(lexer)
    {program, _} = Parser.parse_program(parser)
    program
  end
end
