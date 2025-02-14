defmodule Elixirlang.Evaluator do
  alias Elixirlang.{AST, Object, Environment}

  def eval(node, env \\ Environment.new())

  def eval(%AST.Program{statements: statements}, env) do
    {result, new_env} =
      Enum.reduce(statements, {nil, env}, fn statement, {_, current_env} ->
        {result, updated_env} = eval_with_env(statement, current_env)
        {result, updated_env}
      end)

    {result, new_env}
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
        {result, _} = eval_with_env(statement, current_env)
        # Keep the environment but propagate the result
        {result, current_env}
      end)

    {result, new_env}
  end

  def eval(%AST.Identifier{value: name}, env) do
    {Environment.get(env, name), env}
  end

  def eval(%AST.ListLiteral{elements: elements}, env) do
    {evaluated_elements, new_env} =
      Enum.reduce(elements, {[], env}, fn element, {acc_elements, current_env} ->
        {evaluated, updated_env} = eval_with_env(element, current_env)
        {acc_elements ++ [evaluated], updated_env}
      end)

    {%Object.List{elements: evaluated_elements}, new_env}
  end

  def eval(%AST.PipeExpression{left: left, right: right}, env) do
    {left_val, env} = eval_with_env(left, env)

    case right do
      %AST.CallExpression{function: function, arguments: args} ->
        # Convert the evaluated left value back into an AST node for the function call
        new_args = [to_ast_node(left_val) | args]

        new_call = %AST.CallExpression{
          token: right.token,
          function: function,
          arguments: new_args
        }

        eval_with_env(new_call, env)

      _ ->
        {nil, env}
    end
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

  def eval(%AST.CallExpression{function: function, arguments: arguments}, env) do
    {fn_obj, env} = eval_with_env(function, env)
    {args, env} = eval_arguments(arguments, env)

    case fn_obj do
      %Object.Function{body: :built_in_hd} ->
        case List.first(args) do
          %Object.List{elements: [head | _]} -> {head, env}
          _ -> {nil, env}
        end

      %Object.Function{body: :built_in_tl} ->
        case List.first(args) do
          %Object.List{elements: [_ | tail]} -> {%Object.List{elements: tail}, env}
          _ -> {nil, env}
        end

      %Object.Function{body: :built_in_length} ->
        case List.first(args) do
          %Object.List{elements: elements} -> {%Object.Integer{value: length(elements)}, env}
          _ -> {nil, env}
        end

      %Object.Function{parameters: params, body: body, env: fn_env} ->
        enclosed_env = Environment.new_enclosed(fn_env)

        extended_env =
          Enum.zip(params, args)
          |> Enum.reduce(enclosed_env, fn {param, arg}, acc_env ->
            {_, updated_env} = Environment.set(acc_env, param.value, arg)
            updated_env
          end)

        {result, _} = eval_with_env(body, extended_env)
        {result, env}
    end
  end

  # When evaluating function literals, capture the current environment
  def eval(%AST.FunctionLiteral{parameters: params, body: body}, env) do
    {%Object.Function{parameters: params, body: body, env: env}, env}
  end

  def eval(%AST.StringLiteral{value: value}, env) do
    {Object.String.new(value), env}
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

  # Add this to eval_infix_expression
  defp eval_infix_expression("<>", left, right)
       when is_struct(left, Object.String) and is_struct(right, Object.String) do
    Object.String.new(left.value <> right.value)
  end

  defp eval_infix_expression("==", %Object.String{value: left}, %Object.String{value: right}) do
    Object.Boolean.new(left == right)
  end

  defp eval_infix_expression("!=", %Object.String{value: left}, %Object.String{value: right}) do
    Object.Boolean.new(left != right)
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

  defp to_ast_node(%Object.Integer{value: value}) do
    %AST.IntegerLiteral{value: value}
  end

  defp to_ast_node(%Object.Boolean{value: value}) do
    %AST.BooleanLiteral{value: value}
  end

  defp to_ast_node(%Object.String{value: value}) do
    %AST.StringLiteral{value: value}
  end

  defp to_ast_node(%Object.List{elements: elements}) do
    %AST.ListLiteral{elements: Enum.map(elements, &to_ast_node/1)}
  end

  defp eval_arguments(arguments, env) do
    Enum.reduce(arguments, {[], env}, fn arg, {args_acc, current_env} ->
      {arg_val, updated_env} = eval_with_env(arg, current_env)
      {args_acc ++ [arg_val], updated_env}
    end)
  end
end
