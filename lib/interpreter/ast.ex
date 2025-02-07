defmodule Elixirlang.AST do
  defmodule Program do
    defstruct statements: []

    def token_literal(program) do
      if length(program.statements) > 0 do
        List.first(program.statements).token_literal()
      else
        ""
      end
    end
  end

  defmodule ExpressionStatement do
    defstruct token: nil, expression: nil
    def token_literal(expr_stmt), do: expr_stmt.token.literal
  end

  defmodule IntegerLiteral do
    defstruct token: nil, value: 0
    def token_literal(integer), do: integer.token.literal
  end

  defmodule PrefixExpression do
    defstruct token: nil, operator: "", right: nil
    def token_literal(prefix), do: prefix.token.literal
  end

  defmodule InfixExpression do
    defstruct token: nil, left: nil, operator: "", right: nil
    def token_literal(infix), do: infix.token.literal
  end

  defmodule BooleanLiteral do
    defstruct token: nil, value: false
    def token_literal(boolean), do: boolean.token.literal
  end

  defmodule Identifier do
    defstruct token: nil, value: ""
    def token_literal(identifier), do: identifier.token.literal
  end

  defmodule BlockStatement do
    defstruct token: nil, statements: []
    def token_literal(block), do: block.token.literal
  end

  defmodule IfExpression do
    defstruct token: nil, condition: nil, consequence: nil, alternative: nil
    def token_literal(if_expr), do: if_expr.token.literal
  end

  defmodule PatternMatchExpression do
    defstruct token: nil, left: nil, right: nil
    def token_literal(pattern), do: pattern.token.literal
  end
end
