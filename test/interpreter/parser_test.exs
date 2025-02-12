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

    lexer = Lexer.new(input)
    parser = Parser.new(lexer)
    {program, _} = Parser.parse_program(parser)

    assert length(program.statements) == 1

    stmt = Enum.at(program.statements, 0)

    # Expect a PatternMatchExpression now, not a FunctionLiteral
    assert %AST.PatternMatchExpression{} = pattern_match = stmt

    # Check the left side (function name)
    assert %AST.Identifier{value: "add"} = pattern_match.left

    # Check the right side (function literal)
    assert %AST.FunctionLiteral{} = function = pattern_match.right

    # Verify the function parameters
    assert length(function.parameters) == 2
    assert %AST.Identifier{value: "x"} = Enum.at(function.parameters, 0)
    assert %AST.Identifier{value: "y"} = Enum.at(function.parameters, 1)

    # Verify the function body
    assert %AST.BlockStatement{statements: body_statements} = function.body
    assert length(body_statements) == 1
    assert %AST.ExpressionStatement{} = body_stmt = Enum.at(body_statements, 0)
    assert %AST.InfixExpression{operator: "+"} = body_stmt.expression
  end

  test "parses function call expressions" do
    input = "double(5)"

    program = parse_program(input)
    assert length(program.statements) == 1

    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.CallExpression{} = call = stmt.expression
    assert %AST.Identifier{value: "double"} = call.function
    assert length(call.arguments) == 1
    assert_integer_literal(List.first(call.arguments), 5)
  end

  test "parses nested function calls" do
    input = "into(add(5, 5), add(2, 3))"

    program = parse_program(input)
    assert length(program.statements) == 1

    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.CallExpression{} = outer_call = stmt.expression

    # Verify outer function call (into)
    assert %AST.Identifier{value: "into"} = outer_call.function
    assert length(outer_call.arguments) == 2

    # Verify first nested call (add(5, 5))
    assert %AST.CallExpression{} = first_arg = List.first(outer_call.arguments)
    assert %AST.Identifier{value: "add"} = first_arg.function
    assert length(first_arg.arguments) == 2
    assert_integer_literal(List.first(first_arg.arguments), 5)
    assert_integer_literal(List.last(first_arg.arguments), 5)

    # Verify second nested call (add(2, 3))
    assert %AST.CallExpression{} = second_arg = List.last(outer_call.arguments)
    assert %AST.Identifier{value: "add"} = second_arg.function
    assert length(second_arg.arguments) == 2
    assert_integer_literal(List.first(second_arg.arguments), 2)
    assert_integer_literal(List.last(second_arg.arguments), 3)
  end

  test "parses string literals" do
    input = ~s("hello world")
    program = parse_program(input)

    assert length(program.statements) == 1
    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.StringLiteral{} = stmt.expression
    assert stmt.expression.value == "hello world"
  end

  test "parses string concatenation" do
    input = ~s("Hello" <> " World")
    program = parse_program(input)

    assert length(program.statements) == 1
    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.InfixExpression{} = expr = stmt.expression
    assert expr.operator == "<>"
    assert %AST.StringLiteral{value: "Hello"} = expr.left
    assert %AST.StringLiteral{value: " World"} = expr.right
  end

  test "parses list literals" do
    input = "[1, 2, 3]"
    program = parse_program(input)

    assert length(program.statements) == 1
    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.ListLiteral{} = list = stmt.expression
    assert length(list.elements) == 3

    Enum.each(Enum.zip(list.elements, [1, 2, 3]), fn {element, value} ->
      assert_integer_literal(element, value)
    end)
  end

  test "parses nested list literals" do
    input = "[[1, 2], [3, 4]]"
    program = parse_program(input)

    assert length(program.statements) == 1
    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.ListLiteral{} = outer_list = stmt.expression
    assert length(outer_list.elements) == 2

    Enum.each(outer_list.elements, fn element ->
      assert %AST.ListLiteral{} = element
      assert length(element.elements) == 2
    end)
  end

  test "parses list with expressions" do
    input = "[1 + 2, 3 * 4]"
    program = parse_program(input)

    assert length(program.statements) == 1
    stmt = List.first(program.statements)
    assert %AST.ExpressionStatement{} = stmt
    assert %AST.ListLiteral{} = list = stmt.expression
    assert length(list.elements) == 2

    [first, second] = list.elements
    assert %AST.InfixExpression{operator: "+"} = first
    assert %AST.InfixExpression{operator: "*"} = second
  end
end
