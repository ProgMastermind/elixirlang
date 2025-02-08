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

  def eval(%AST.InfixExpression{left: left, operator: operator, right: right}) do
    left_eval = eval(left)
    right_eval = eval(right)
    eval_infix_expression(operator, left_eval, right_eval)
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

  defp eval_infix_expression(operator, %Object.Integer{} = left, %Object.Integer{} = right) do
    eval_integer_infix_expression(operator, left, right)
  end

  defp eval_infix_expression(operator, %Object.Boolean{} = left, %Object.Boolean{} = right) do
    eval_boolean_infix_expression(operator, left, right)
  end

  defp eval_infix_expression(_, _, _), do: nil

  defp eval_integer_infix_expression("+", %Object.Integer{value: left}, %Object.Integer{
         value: right
       }) do
    Object.Integer.new(left + right)
  end

  defp eval_integer_infix_expression("-", %Object.Integer{value: left}, %Object.Integer{
         value: right
       }) do
    Object.Integer.new(left - right)
  end

  defp eval_integer_infix_expression("*", %Object.Integer{value: left}, %Object.Integer{
         value: right
       }) do
    Object.Integer.new(left * right)
  end

  defp eval_integer_infix_expression("/", %Object.Integer{value: left}, %Object.Integer{
         value: right
       }) do
    Object.Integer.new(div(left, right))
  end

  defp eval_integer_infix_expression("<", %Object.Integer{value: left}, %Object.Integer{
         value: right
       }) do
    Object.Boolean.new(left < right)
  end

  defp eval_integer_infix_expression(">", %Object.Integer{value: left}, %Object.Integer{
         value: right
       }) do
    Object.Boolean.new(left > right)
  end

  defp eval_integer_infix_expression("==", %Object.Integer{value: left}, %Object.Integer{
         value: right
       }) do
    Object.Boolean.new(left == right)
  end

  defp eval_integer_infix_expression("!=", %Object.Integer{value: left}, %Object.Integer{
         value: right
       }) do
    Object.Boolean.new(left != right)
  end

  defp eval_integer_infix_expression("<=", %Object.Integer{value: left}, %Object.Integer{
         value: right
       }) do
    Object.Boolean.new(left <= right)
  end

  defp eval_integer_infix_expression(">=", %Object.Integer{value: left}, %Object.Integer{
         value: right
       }) do
    Object.Boolean.new(left >= right)
  end

  defp eval_boolean_infix_expression("==", %Object.Boolean{value: left}, %Object.Boolean{
         value: right
       }) do
    Object.Boolean.new(left == right)
  end

  defp eval_boolean_infix_expression("!=", %Object.Boolean{value: left}, %Object.Boolean{
         value: right
       }) do
    Object.Boolean.new(left != right)
  end
end
