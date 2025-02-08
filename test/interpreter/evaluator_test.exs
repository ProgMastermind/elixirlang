defmodule Elixirlang.EvaluatorTest do
  use ExUnit.Case
  alias Elixirlang.{Lexer, Parser, Evaluator}

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

  defp eval(input) do
    lexer = Lexer.new(input)
    parser = Parser.new(lexer)
    {program, _} = Parser.parse_program(parser)
    Evaluator.eval(program)
  end

  defp assert_integer_object(object, expected) do
    assert %Elixirlang.Object.Integer{} = object
    assert object.value == expected
  end
end
