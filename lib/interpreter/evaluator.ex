defmodule Elixirlang.Evaluator do
  alias Elixirlang.{AST, Object, Environment}

  def eval(node, env \\ Environment.new())

  def eval(%AST.Program{statements: statements}, env) do
    statements
    |> Enum.reduce({nil, env}, fn statement, {_, current_env} ->
      {result, new_env} = eval_with_env(statement, current_env)
      {result, new_env}
    end)
    |> elem(0)
  end

  def eval(%AST.ExpressionStatement{expression: expression}, env) do
    eval_with_env(expression, env)
  end

  def eval(%AST.IntegerLiteral{value: value}, env) do
    {Object.Integer.new(value), env}
  end

  def eval(%AST.BooleanLiteral{value: value}, env) do
    {Object.Boolean.new(value), env}
  end

  def eval(%AST.PrefixExpression{operator: operator, right: right}, env) do
    {right_eval, env} = eval_with_env(right, env)
    {eval_prefix_expression(operator, right_eval), env}
  end

  def eval(%AST.InfixExpression{left: left, operator: operator, right: right}, env) do
    {left_eval, env} = eval_with_env(left, env)
    {right_eval, env} = eval_with_env(right, env)
    {eval_infix_expression(operator, left_eval, right_eval), env}
  end

  def eval(
        %AST.IfExpression{
          condition: condition,
          consequence: consequence,
          alternative: alternative
        },
        env
      ) do
    {condition_eval, env} = eval_with_env(condition, env)

    cond do
      is_truthy?(condition_eval) -> eval_with_env(consequence, env)
      alternative != nil -> eval_with_env(alternative, env)
      true -> {nil, env}
    end
  end

  def eval(%AST.BlockStatement{statements: statements}, env) do
    {result, new_env} =
      Enum.reduce(statements, {nil, env}, fn statement, {_, current_env} ->
        eval_with_env(statement, current_env)
      end)

    {result, new_env}
  end

  def eval(%AST.Identifier{value: name}, env) do
    {Environment.get(env, name), env}
  end

  def eval(%AST.PatternMatchExpression{left: left, right: right}, env) do
    case left do
      %AST.Identifier{value: name} ->
        {right_eval, new_env} = eval_with_env(right, env)
        {right_eval, Environment.set(new_env, name, right_eval) |> elem(1)}

      _ ->
        {nil, env}
    end
  end

  def eval(nil, env), do: {nil, env}

  defp eval_with_env(node, env) do
    eval(node, env)
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

  defp is_truthy?(%Object.Boolean{value: false}), do: false
  defp is_truthy?(nil), do: false
  defp is_truthy?(_), do: true
end
