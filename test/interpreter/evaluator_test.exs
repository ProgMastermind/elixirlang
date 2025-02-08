defmodule Elixirlang.EvaluatorTest do
  use ExUnit.Case
  alias Elixirlang.{Lexer, Parser, Evaluator, Object}

  describe "integer evaluation" do
    test "evaluates integer expressions" do
      tests = [
        {"5", 5},
        {"10", 10},
        {"999", 999}
      ]

      Enum.each(tests, fn {input, expected} ->
        evaluated = eval(input)
        assert_integer_object(evaluated, expected)
      end)
    end
  end

  describe "boolean evaluation" do
    test "evaluates boolean expressions" do
      tests = [
        {"true", true},
        {"false", false}
      ]

      Enum.each(tests, fn {input, expected} ->
        evaluated = eval(input)
        assert_boolean_object(evaluated, expected)
      end)
    end
  end

  describe "prefix expressions" do
    test "evaluates bang operator" do
      tests = [
        {"!true", false},
        {"!false", true},
        {"!!true", true},
        {"!!false", false}
      ]

      Enum.each(tests, fn {input, expected} ->
        evaluated = eval(input)
        assert_boolean_object(evaluated, expected)
      end)
    end

    test "evaluates minus operator" do
      tests = [
        {"-5", -5},
        {"-10", -10},
        {"--5", 5}
      ]

      Enum.each(tests, fn {input, expected} ->
        evaluated = eval(input)
        assert_integer_object(evaluated, expected)
      end)
    end

    test "evaluates plus operator" do
      tests = [
        {"+5", 5},
        {"+10", 10}
      ]

      Enum.each(tests, fn {input, expected} ->
        evaluated = eval(input)
        assert_integer_object(evaluated, expected)
      end)
    end
  end

  describe "infix expressions" do
    test "evaluates integer operations" do
      tests = [
        {"5 + 5", 10},
        {"5 - 5", 0},
        {"5 * 5", 25},
        {"5 / 5", 1},
        {"50 / 2 * 2 + 10", 60},
        {"2 * 2 * 2 * 2", 16},
        {"5 * 2 + 10", 20},
        {"5 + 2 * 10", 25}
      ]

      Enum.each(tests, fn {input, expected} ->
        evaluated = eval(input)
        assert_integer_object(evaluated, expected)
      end)
    end

    test "evaluates integer comparisons" do
      tests = [
        {"5 < 6", true},
        {"5 > 6", false},
        {"5 == 5", true},
        {"5 != 5", false},
        {"5 >= 5", true},
        {"5 <= 4", false}
      ]

      Enum.each(tests, fn {input, expected} ->
        evaluated = eval(input)
        assert_boolean_object(evaluated, expected)
      end)
    end

    test "evaluates boolean operations" do
      tests = [
        {"true == true", true},
        {"false == false", true},
        {"true == false", false},
        {"true != false", true},
        {"false != true", true}
      ]

      Enum.each(tests, fn {input, expected} ->
        evaluated = eval(input)
        assert_boolean_object(evaluated, expected)
      end)
    end
  end

  defp eval(input) do
    lexer = Lexer.new(input)
    parser = Parser.new(lexer)
    {program, _} = Parser.parse_program(parser)
    Evaluator.eval(program)
  end

  defp assert_integer_object(object, expected) do
    assert %Object.Integer{} = object
    assert object.value == expected
  end

  defp assert_boolean_object(object, expected) do
    assert %Object.Boolean{} = object
    assert object.value == expected
  end
end
