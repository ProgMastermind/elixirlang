defmodule Elixirlang.Evaluator do
  alias Elixirlang.{AST, Object}

  def eval(%AST.Program{statements: statements}) do
    eval_statements(statements)
  end

  def eval(%AST.ExpressionStatement{expression: expression}) do
    eval(expression)
  end

  def eval(%AST.IntegerLiteral{value: value}) do
    Object.Integer.new(value)
  end

  def eval(%AST.BooleanLiteral{value: value}) do
    Object.Boolean.new(value)
  end

  defp eval_statements(statements) do
    statements
    |> List.last()
    |> eval()
  end
end
