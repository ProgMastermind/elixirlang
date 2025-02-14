defmodule Elixirlang.Environment do
  @moduledoc """
  Manages variable bindings and scopes.
  Provides closure support for functions.

  Built-in functions:
  - hd/1: Returns first element of list
  - tl/1: Returns list without first element
  - length/1: Returns list length
  """

  defstruct store: %{}, outer: nil

  @doc """
  Creates a new environment with built-in functions.
  """
  def new do
    %__MODULE__{
      store: %{
        "hd" => %Elixirlang.Object.Function{
          parameters: [%Elixirlang.AST.Identifier{value: "list"}],
          body: :built_in_hd,
          env: nil
        },
        "tl" => %Elixirlang.Object.Function{
          parameters: [%Elixirlang.AST.Identifier{value: "list"}],
          body: :built_in_tl,
          env: nil
        },
        "length" => %Elixirlang.Object.Function{
          parameters: [%Elixirlang.AST.Identifier{value: "list"}],
          body: :built_in_length,
          env: nil
        }
      },
      outer: nil
    }
  end

  @doc """
  Creates a new enclosed environment with an outer scope.
  Used for function calls to maintain proper closure behavior.
  """
  def new_enclosed(outer) do
    %__MODULE__{store: %{}, outer: outer}
  end

  @doc """
  Gets a value from the environment by name.
  Searches outer scopes if not found in current scope.
  """
  def get(env, name) do
    case Map.fetch(env.store, name) do
      {:ok, value} -> value
      :error when not is_nil(env.outer) -> get(env.outer, name)
      :error -> nil
    end
  end

  @doc """
  Sets a value in the current environment scope.

  ## Parameters
    - env: The current environment
    - name: The variable name
    - value: The value to store

  ## Returns
    `{value, new_environment}`
  """
  def set(env, name, value) do
    {value, %{env | store: Map.put(env.store, name, value)}}
  end
end
