defmodule Elixirlang.REPL do
  alias Elixirlang.{Lexer, Parser, Evaluator, Environment, Object}

  @prompt "\n\e[36m╭─\e[0m \e[1;32mElixirlang\e[0m \e[34m→\e[0m "
  # @continuation_prompt "\e[36m╰─➤\e[0m "

  def start do
    env = Environment.new()
    display_welcome_banner()
    loop(env)
  end

  defp display_welcome_banner do
    IO.puts("""
    \e[1;35m
    ╔════════════════════════════════════╗
    ║     Welcome to Elixirlang REPL     ║
    ╚════════════════════════════════════╝\e[0m

    \e[33mType '.exit' to quit\e[0m
    \e[2mVersion 1.0.0\e[0m
    """)
  end

  defp loop(env) do
    IO.write(@prompt)

    case IO.gets("") do
      :eof ->
        IO.puts("\n\e[1;35mGoodbye! Thanks for using Elixirlang REPL\e[0m")

      ".exit\n" ->
        IO.puts("\n\e[1;35mGoodbye! Thanks for using Elixirlang REPL\e[0m")

      input ->
        {result, new_env} = eval(input, env)
        print_result(result)
        loop(new_env)
    end
  end

  defp eval(input, env) do
    lexer = Lexer.new(input)
    parser = Parser.new(lexer)
    {program, _} = Parser.parse_program(parser)
    Evaluator.eval(program, env)
  end

  defp print_result(%Object.Integer{value: value}), do: IO.puts("\e[33m=> #{value}\e[0m")
  defp print_result(%Object.Boolean{value: value}), do: IO.puts("\e[33m=> #{value}\e[0m")
  defp print_result(%Object.String{value: value}), do: IO.puts("\e[33m=> \"#{value}\"\e[0m")
  defp print_result(%Object.Function{}), do: IO.puts("\e[33m=> <function>\e[0m")

  defp print_result(%Object.List{elements: elements}) do
    formatted_elements =
      elements
      |> Enum.map(fn
        %Object.Integer{value: v} -> Integer.to_string(v)
        %Object.Boolean{value: v} -> to_string(v)
        %Object.String{value: v} -> "\"#{v}\""
        %Object.List{} = list -> format_nested_list(list)
        _ -> "nil"
      end)
      |> Enum.join(", ")

    IO.puts("\e[33m=> [#{formatted_elements}]\e[0m")
  end

  defp print_result(nil), do: IO.puts("\e[33m=> nil\e[0m")
  defp print_result(result), do: IO.puts("\e[33m=> #{inspect(result)}\e[0m")

  defp format_nested_list(%Object.List{elements: elements}) do
    formatted_elements =
      elements
      |> Enum.map(fn
        %Object.Integer{value: v} -> Integer.to_string(v)
        %Object.Boolean{value: v} -> to_string(v)
        %Object.String{value: v} -> "\"#{v}\""
        %Object.List{} = list -> format_nested_list(list)
        _ -> "nil"
      end)
      |> Enum.join(", ")

    "[#{formatted_elements}]"
  end
end
