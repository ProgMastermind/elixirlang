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
end
