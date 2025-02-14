defmodule Elixirlang.Environment do
  defstruct store: %{}, outer: nil

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

  def new_enclosed(outer) do
    %__MODULE__{store: %{}, outer: outer}
  end

  def get(env, name) do
    case Map.fetch(env.store, name) do
      {:ok, value} -> value
      :error when not is_nil(env.outer) -> get(env.outer, name)
      :error -> nil
    end
  end

  def set(env, name, value) do
    {value, %{env | store: Map.put(env.store, name, value)}}
  end
end
