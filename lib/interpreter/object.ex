defmodule Elixirlang.Object do
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

  def type(%Integer{}), do: Integer.type()
  def type(%Boolean{}), do: Boolean.type()
  def type(%Function{}), do: Function.type()
end
