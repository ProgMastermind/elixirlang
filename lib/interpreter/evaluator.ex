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

  def eval(%AST.PrefixExpression{operator: operator, right: right}) do
    right_eval = eval(right)
    eval_prefix_expression(operator, right_eval)
  end

  defp eval_statements(statements) do
    statements
    |> List.last()
    |> eval()
  end

  defp eval_prefix_expression("!", right), do: eval_bang_operator(right)
  defp eval_prefix_expression("-", right), do: eval_minus_operator(right)
  defp eval_prefix_expression("+", right), do: right

  defp eval_bang_operator(%Object.Boolean{value: true}), do: Object.Boolean.new(false)
  defp eval_bang_operator(%Object.Boolean{value: false}), do: Object.Boolean.new(true)
  defp eval_bang_operator(_), do: Object.Boolean.new(false)

  defp eval_minus_operator(%Object.Integer{value: value}), do: Object.Integer.new(-value)
  defp eval_minus_operator(_), do: nil
end
