defmodule Elixirlang.Environment do
  defstruct store: %{}

  def new do
    %__MODULE__{}
  end

  def get(env, name) do
    Map.get(env.store, name)
  end

  def set(env, name, value) do
    {value, %{env | store: Map.put(env.store, name, value)}}
  end
end
