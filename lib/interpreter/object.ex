defmodule Elixirlang.Object do
  @moduledoc """
  Defines the runtime objects used in the interpreter.
  Each type represents a different kind of value that can be
  manipulated during program execution.
  """

  defmodule Integer do
    @enforce_keys [:value]
    defstruct [:value]

    def new(value) when is_integer(value) do
      %__MODULE__{value: value}
    end

    def type, do: :INTEGER
  end

  defmodule Boolean do
    @enforce_keys [:value]
    defstruct [:value]

    def new(value) when is_boolean(value) do
      %__MODULE__{value: value}
    end

    def type, do: :BOOLEAN
  end

  defmodule Function do
    @enforce_keys [:parameters, :body, :env]
    defstruct [:parameters, :body, :env]

    def type, do: :FUNCTION
  end

  defmodule String do
    @enforce_keys [:value]
    defstruct [:value]

    def new(value) when is_binary(value) do
      %__MODULE__{value: value}
    end

    def type, do: :STRING
  end

  defmodule List do
    @enforce_keys [:elements]
    defstruct [:elements]

    def new(elements) when is_list(elements) do
      %__MODULE__{elements: elements}
    end

    def type, do: :LIST
  end

  defmodule Pipe do
    @enforce_keys [:left, :right]
    defstruct [:left, :right]

    def new(left, right) do
      %__MODULE__{left: left, right: right}
    end

    def type, do: :PIPE
  end

  def type(%Pipe{}), do: Pipe.type()
  def type(%Integer{}), do: Integer.type()
  def type(%Boolean{}), do: Boolean.type()
  def type(%Function{}), do: Function.type()
  def type(%String{}), do: String.type()
  def type(%List{}), do: List.type()
end
