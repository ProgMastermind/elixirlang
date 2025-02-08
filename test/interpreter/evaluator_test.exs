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
