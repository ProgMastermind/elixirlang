defmodule Elixirlang.Token do
  @type t :: %__MODULE__{
          type: atom(),
          literal: String.t()
        }

  defstruct [:type, :literal]

  # Token types
  def illegal, do: :ILLEGAL
  def eof, do: :EOF

  # Identifiers and literals
  def ident, do: :IDENT
  def int, do: :INT
  def string, do: :STRING
  def atom, do: :ATOM

  # Operators
  def assign, do: :ASSIGN
  def plus, do: :PLUS
  def minus, do: :MINUS
  def bang, do: :BANG
  def asterisk, do: :ASTERISK
  def slash, do: :SLASH

  # Delimiters
  def comma, do: :COMMA
  def semicolon, do: :SEMICOLON
  def lparen, do: :LPAREN
  def rparen, do: :RPAREN
  def lbrace, do: :LBRACE
  def rbrace, do: :RBRACE

  # Keywords
  def function, do: :FUNCTION
  def def_, do: :DEF
  def do_, do: :DO
  def end_, do: :END
  def true_, do: :TRUE
  def false_, do: :FALSE
  def if_, do: :IF
  def else_, do: :ELSE
  def return, do: :RETURN

  def keywords do
    %{
      "def" => :DEF,
      "do" => :DO,
      "end" => :END,
      "true" => :TRUE,
      "false" => :FALSE,
      "if" => :IF,
      "else" => :ELSE,
      "return" => :RETURN
    }
  end

  def lookup_ident(ident) do
    Map.get(keywords(), ident, :IDENT)
  end

  def new(type, literal) do
    %__MODULE__{type: type, literal: literal}
  end
end
