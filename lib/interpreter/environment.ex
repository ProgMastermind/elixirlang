defmodule Elixirlang.Environment do
  defstruct store: %{}, outer: nil

  def new do
    %__MODULE__{store: %{}, outer: nil}
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
    # Always set in current environment, allowing shadowing
    {value, %{env | store: Map.put(env.store, name, value)}}
  end
end
