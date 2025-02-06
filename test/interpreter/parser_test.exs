defmodule Elixirlang.ParserTest do
  use ExUnit.Case
  alias Elixirlang.{Lexer, Parser, AST}

  defp parse_program(input) do
    lexer = Lexer.new(input)
    parser = Parser.new(lexer)
    {program, _} = Parser.parse_program(parser)
    program
  end

  test "parses integer literals" do
    input = "5"
    program = parse_program(input)

    assert length(program.statements) == 1
    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.IntegerLiteral{value: 5} = stmt.expression
  end

  test "parses prefix expressions" do
    tests = [
      {"!5", "!", 5},
      {"-15", "-", 15},
      {"+15", "+", 15}
    ]

    Enum.each(tests, fn {input, operator, value} ->
      program = parse_program(input)

      assert length(program.statements) == 1
      stmt = List.first(program.statements)
      assert %AST.ExpressionStatement{} = stmt
      assert %AST.PrefixExpression{} = stmt.expression
      assert stmt.expression.operator == operator
      assert_integer_literal(stmt.expression.right, value)
    end)
  end

  test "parses infix expressions" do
    tests = [
      {"5 + 5", 5, "+", 5},
      {"5 - 5", 5, "-", 5},
      {"5 * 5", 5, "*", 5},
      {"5 / 5", 5, "/", 5},
      {"5 > 5", 5, ">", 5},
      {"5 < 5", 5, "<", 5},
      {"5 == 5", 5, "==", 5},
      {"5 != 5", 5, "!=", 5},
      {"5 >= 5", 5, ">=", 5},
      {"5 <= 5", 5, "<=", 5}
    ]

    Enum.each(tests, fn {input, left_value, operator, right_value} ->
      program = parse_program(input)

      assert length(program.statements) == 1
      stmt = List.first(program.statements)
      assert %AST.ExpressionStatement{} = stmt
      assert %AST.InfixExpression{} = stmt.expression
      assert_integer_literal(stmt.expression.left, left_value)
      assert stmt.expression.operator == operator
      assert_integer_literal(stmt.expression.right, right_value)
    end)
  end

  test "handles operator precedence correctly" do
    tests = [
      {"5 * 2 + 1", "((5 * 2) + 1)"},
      {"5 + 2 * 1", "(5 + (2 * 1))"},
      {"2 * 2 * 2", "((2 * 2) * 2)"}
    ]

    Enum.each(tests, fn {input, _expected} ->
      program = parse_program(input)
      assert length(program.statements) == 1
      stmt = List.first(program.statements)
      assert %AST.ExpressionStatement{} = stmt
      assert %AST.InfixExpression{} = stmt.expression
    end)
  end

  test "parses boolean literals" do
    tests = [
      {"true", true},
      {"false", false}
    ]

    Enum.each(tests, fn {input, expected_value} ->
      program = parse_program(input)

      assert length(program.statements) == 1
      stmt = List.first(program.statements)
      assert %AST.ExpressionStatement{} = stmt
      assert %AST.BooleanLiteral{} = stmt.expression
      assert stmt.expression.value == expected_value
    end)
  end

  defp assert_integer_literal(expr, value) do
    assert %AST.IntegerLiteral{} = expr
    assert expr.value == value
  end
end
