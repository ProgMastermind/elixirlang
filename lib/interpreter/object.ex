defmodule Elixirlang.Object do
  defmodule Integer do
    defstruct [:value]

    def new(value) when is_integer(value) do
      %__MODULE__{value: value}
    end

    def type, do: :INTEGER
  end

  defmodule Boolean do
    defstruct [:value]

    def new(value) when is_boolean(value) do
      %__MODULE__{value: value}
    end

    def type, do: :BOOLEAN
  end

  def type(%Integer{}), do: Integer.type()
  def type(%Boolean{}), do: Boolean.type()
end
