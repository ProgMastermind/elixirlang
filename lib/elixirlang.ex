defmodule Elixirlang do
  @moduledoc """
  A simple interpreter implementation in Elixir.

  Version: 1.0.0
  Platform: Elixir #{System.version()}

  Features:
  - Integer arithmetic
  - String operations
  - List manipulation
  - Function definitions
  - Pattern matching
  - Pipe operator
  - Built-in functions

  ## Usage
      iex> Elixirlang.main()
      # Starts the REPL

  ## Examples
      5 + 3 * 2
      "Hello" <> " World"
      [1, 2, 3] |> length()
  """

  def main(_args \\ []) do
    Elixirlang.REPL.start()
  end
end
