defmodule Elixirlang.REPL do
  alias Elixirlang.{Lexer, Parser, Evaluator, Environment, Object}

  @colors %{
    prompt: :cyan,
    result: :yellow,
    info: :green,
    type: :blue
  }

  @prompts %{
    main: "╭─ λ ",
    continue: "╰─➤ "
  }

  defmodule State do
    defstruct env: nil,
              multiline_buffer: []
  end

  def start do
    state = %State{env: Environment.new()}
    display_welcome_banner()
    loop(state)
  end

  defp display_welcome_banner do
    banner = """
    #{color("╔════════════════════════════════════════════╗", :prompt)}
    #{color("║           Elixirlang Interactive           ║", :prompt)}
    #{color("╚════════════════════════════════════════════╝", :prompt)}

    #{color("Commands:", :type)}
    #{color("  .help    - Show help", :info)}
    #{color("  .example - Show examples", :info)}
    #{color("  .exit    - Exit REPL", :info)}
    """

    IO.puts(banner)
  end

  defp loop(%State{} = state) do
    input = read_input(state)

    case handle_input(input, state) do
      {:exit, _} ->
        IO.puts("\n#{color("Goodbye! Thanks for using Elixirlang", :info)}")

      {:continue, new_state} ->
        loop(new_state)
    end
  end

  defp read_input(%State{multiline_buffer: []} = _state) do
    IO.write(color(@prompts.main, :prompt))
    IO.gets("")
  end

  defp read_input(%State{multiline_buffer: _buffer} = _state) do
    IO.write(color(@prompts.continue, :prompt))
    IO.gets("")
  end

  defp handle_input(input, state) do
    case String.trim(input) do
      ".exit" ->
        {:exit, state}

      ".help" ->
        handle_help()
        {:continue, state}

      ".example" ->
        handle_example()
        {:continue, state}

      input ->
        handle_code_input(input, state)
    end
  end

  defp handle_code_input(input, state) do
    new_buffer = state.multiline_buffer ++ [input]
    code = Enum.join(new_buffer, "\n")

    if complete_expression?(code) do
      {result, new_env} = eval(String.trim(code), state.env)
      print_result(result)
      {:continue, %State{state | env: new_env, multiline_buffer: []}}
    else
      {:continue, %State{state | multiline_buffer: new_buffer}}
    end
  end

  defp complete_expression?(code) do
    code = String.trim(code)
    lines = String.split(code, "\n", trim: true)

    balanced_do = count_keyword(code, "do") == count_keyword(code, "end")
    balanced_brackets = count_chars(code, "[") == count_chars(code, "]")
    balanced_parens = count_chars(code, "(") == count_chars(code, ")")

    # For single-line expressions
    if length(lines) == 1 do
      balanced_brackets && balanced_parens &&
        (!String.contains?(code, "do") ||
           (String.contains?(code, "do") && String.contains?(code, "end")))
    else
      # For multiline expressions
      last_line = List.last(lines) |> String.trim()

      balanced_do && balanced_brackets && balanced_parens &&
        (String.ends_with?(last_line, "end") || !String.contains?(code, "do"))
    end
  end

  defp count_keyword(str, keyword) do
    str
    |> String.split(keyword)
    |> length()
    |> Kernel.-(1)
    |> max(0)
  end

  defp count_chars(str, char) do
    str
    |> String.graphemes()
    |> Enum.count(&(&1 == char))
  end

  defp eval(input, env) do
    lexer = Lexer.new(input)
    parser = Parser.new(lexer)
    {program, _} = Parser.parse_program(parser)
    Evaluator.eval(program, env)
  end

  defp print_result(%Object.Integer{value: value}),
    do: IO.puts("#{color("=>", :result)} #{value}")

  defp print_result(%Object.Boolean{value: value}),
    do: IO.puts("#{color("=>", :result)} #{value}")

  defp print_result(%Object.String{value: value}),
    do: IO.puts("#{color("=>", :result)} \"#{value}\"")

  defp print_result(%Object.Function{}), do: IO.puts("#{color("=>", :result)} <function>")

  defp print_result(%Object.List{elements: elements}),
    do: IO.puts("#{color("=>", :result)} #{format_list(elements)}")

  defp print_result(nil), do: IO.puts("#{color("=>", :result)} nil")

  defp format_list(elements) do
    inner =
      elements
      |> Enum.map(fn
        %Object.Integer{value: v} -> "#{v}"
        %Object.Boolean{value: v} -> "#{v}"
        %Object.String{value: v} -> "\"#{v}\""
        %Object.List{elements: e} -> format_list(e)
        _ -> "nil"
      end)
      |> Enum.join(", ")

    "[#{inner}]"
  end

  defp handle_help do
    help_text = """

    #{color("Available Commands:", :type)}
    #{color("  .help    - Show this help", :info)}
    #{color("  .example - Show examples", :info)}
    #{color("  .exit    - Exit REPL", :info)}

    #{color("Features:", :type)}
    #{color("  • Integer arithmetic: 1 + 2 * 3", :info)}
    #{color("  • String operations: \"hello\" <> \" world\"", :info)}
    #{color("  • List manipulation: [1, 2, 3] |> length()", :info)}
    #{color("  • Functions: def add(x, y) do x + y end", :info)}
    #{color("  • Pattern matching: x = 5", :info)}
    #{color("  • Conditionals: if (x > 0) do \"positive\" else \"negative\" end", :info)}
    """

    IO.puts(help_text)
  end

  defp handle_example do
    example_text = """

    #{color("# Try these examples:", :type)}

    #{color("# Arithmetic", :info)}
    5 + 3 * 2

    #{color("# Functions", :info)}
    def add(x, y) do a + b end
    add(2, 3)

    #{color("# Lists", :info)}
    [1, 2, 3] |> length()
    [[1+2], [3+4]]

    #{color("# Pattern Matching", :info)}
    x = 5
    y = x + 3
    """

    IO.puts(example_text)
  end

  defp color(text, color_name) do
    IO.ANSI.format([Map.get(@colors, color_name), text, :reset])
    |> IO.iodata_to_binary()
  end
end
