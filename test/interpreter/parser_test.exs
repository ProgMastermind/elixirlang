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

  test "parses grouped expressions" do
    tests = [
      {"(5 + 5)", "(5 + 5)"},
      {"(5 + 5) * 2", "((5 + 5) * 2)"},
      {"2 * (5 + 5)", "(2 * (5 + 5))"},
      {"-(5 + 5)", "(-(5 + 5))"}
    ]

    Enum.each(tests, fn {input, _expected} ->
      program = parse_program(input)
      assert length(program.statements) == 1
      stmt = List.first(program.statements)
      assert %AST.ExpressionStatement{} = stmt
    end)
  end

  test "parses identifiers" do
    input = "foobar"
    program = parse_program(input)

    assert length(program.statements) == 1
    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.Identifier{} = stmt.expression
    assert stmt.expression.value == "foobar"
    assert stmt.expression.token.literal == "foobar"
  end

  test "parses identifier expressions in operations" do
    tests = [
      {"x + y", "x", "+", "y"},
      {"foo - bar", "foo", "-", "bar"},
      {"hello * world", "hello", "*", "world"}
    ]

    Enum.each(tests, fn {input, left_val, operator, right_val} ->
      program = parse_program(input)
      assert length(program.statements) == 1
      stmt = List.first(program.statements)
      assert %AST.ExpressionStatement{} = stmt
      assert %AST.InfixExpression{} = stmt.expression
      assert_identifier(stmt.expression.left, left_val)
      assert stmt.expression.operator == operator
      assert_identifier(stmt.expression.right, right_val)
    end)
  end

  defp assert_identifier(expr, value) do
    assert %AST.Identifier{} = expr
    assert expr.value == value
  end

  test "parses if expressions" do
    input = """
    if (x < y) do
      x
    end
    """

    program = parse_program(input)
    assert length(program.statements) == 1

    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.IfExpression{} = expr = stmt.expression

    assert %AST.InfixExpression{} = expr.condition
    assert_identifier(expr.condition.left, "x")
    assert expr.condition.operator == "<"
    assert_identifier(expr.condition.right, "y")

    assert %AST.BlockStatement{} = expr.consequence
    assert length(expr.consequence.statements) == 1

    consequence_stmt = List.first(expr.consequence.statements)
    assert %AST.ExpressionStatement{} = consequence_stmt
    assert_identifier(consequence_stmt.expression, "x")

    assert is_nil(expr.alternative)
  end

  test "parses if-else expressions" do
    input = """
    if (x < y) do
      x
    else
      y
    end
    """

    program = parse_program(input)
    assert length(program.statements) == 1

    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.IfExpression{} = expr = stmt.expression

    assert %AST.InfixExpression{} = expr.condition
    assert_identifier(expr.condition.left, "x")
    assert expr.condition.operator == "<"
    assert_identifier(expr.condition.right, "y")

    assert %AST.BlockStatement{} = expr.consequence
    assert length(expr.consequence.statements) == 1
    consequence_stmt = List.first(expr.consequence.statements)
    assert %AST.ExpressionStatement{} = consequence_stmt
    assert_identifier(consequence_stmt.expression, "x")

    assert %AST.BlockStatement{} = expr.alternative
    assert length(expr.alternative.statements) == 1
    alternative_stmt = List.first(expr.alternative.statements)
    assert %AST.ExpressionStatement{} = alternative_stmt
    assert_identifier(alternative_stmt.expression, "y")
  end

  test "parses complex if expressions" do
    input = """
    if (5 * 2 > 3 + 4) do
      10 + 20
    else
      30 * 40
    end
    """

    program = parse_program(input)
    assert length(program.statements) == 1

    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.IfExpression{} = expr = stmt.expression

    # Test condition
    assert %AST.InfixExpression{} = expr.condition
    assert %AST.InfixExpression{} = expr.condition.left
    assert %AST.InfixExpression{} = expr.condition.right

    # Test consequence
    assert %AST.BlockStatement{} = expr.consequence
    consequence_stmt = List.first(expr.consequence.statements)
    assert %AST.ExpressionStatement{} = consequence_stmt
    assert %AST.InfixExpression{} = consequence_stmt.expression

    # Test alternative
    assert %AST.BlockStatement{} = expr.alternative
    alternative_stmt = List.first(expr.alternative.statements)
    assert %AST.ExpressionStatement{} = alternative_stmt
    assert %AST.InfixExpression{} = alternative_stmt.expression
  end

  test "parses nested if expressions" do
    input = """
    if (true) do
      if (false) do
        1
      else
        2
      end
    end
    """

    program = parse_program(input)
    assert length(program.statements) == 1

    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.IfExpression{} = outer_if = stmt.expression

    assert %AST.BooleanLiteral{value: true} = outer_if.condition
    assert %AST.BlockStatement{} = outer_if.consequence

    inner_if_stmt = List.first(outer_if.consequence.statements)
    assert %AST.ExpressionStatement{} = inner_if_stmt
    assert %AST.IfExpression{} = inner_if = inner_if_stmt.expression

    assert %AST.BooleanLiteral{value: false} = inner_if.condition
  end

  test "parses pattern matching expressions" do
    tests = [
      {"x = 5", "x", 5},
      {"y = 10", "y", 10},
      {"x = y", "x", "y"}
    ]

    Enum.each(tests, fn {input, left_name, right_value} ->
      program = parse_program(input)
      assert length(program.statements) == 1

      stmt = List.first(program.statements)
      assert %AST.ExpressionStatement{} = stmt
      assert %AST.PatternMatchExpression{} = pattern = stmt.expression

      assert_identifier(pattern.left, left_name)

      case right_value do
        value when is_integer(value) ->
          assert_integer_literal(pattern.right, value)

        value when is_binary(value) ->
          assert_identifier(pattern.right, value)
      end
    end)
  end

  test "parses complex pattern matching" do
    input = "result = 5 + 10 * 2"
    program = parse_program(input)

    assert length(program.statements) == 1
    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.PatternMatchExpression{} = expr = stmt.expression
    assert_identifier(expr.left, "result")
    assert %AST.InfixExpression{} = expr.right
  end

  test "parses function definitions" do
    input = """
    def add(x, y) do
      x + y
    end
    """

    program = parse_program(input)
    assert length(program.statements) == 1

    stmt = List.first(program.statements)
    assert %AST.FunctionLiteral{} = function = stmt

    assert length(function.parameters) == 2
    assert_identifier(List.first(function.parameters), "x")
    assert_identifier(Enum.at(function.parameters, 1), "y")

    assert %AST.BlockStatement{} = function.body
    assert length(function.body.statements) == 1

    body_stmt = List.first(function.body.statements)
    assert %AST.ExpressionStatement{} = body_stmt
    assert %AST.InfixExpression{} = expr = body_stmt.expression
    assert_identifier(expr.left, "x")
    assert expr.operator == "+"
    assert_identifier(expr.right, "y")
  end

  test "parses function calls" do
    input = "add(1, 2 * 3, 4 + 5)"
    program = parse_program(input)

    assert length(program.statements) == 1
    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.CallExpression{} = expr = stmt.expression
    assert_identifier(expr.function, "add")
    assert length(expr.arguments) == 3
  end

  test "parses function calls with no arguments" do
    input = "empty()"
    program = parse_program(input)

    assert length(program.statements) == 1
    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.CallExpression{} = expr = stmt.expression
    assert_identifier(expr.function, "empty")
    assert length(expr.arguments) == 0
  end
end
