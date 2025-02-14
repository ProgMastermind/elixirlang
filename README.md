````markdown
# ElixirLang Interpreter

A simple yet educational interpreter implementation in Elixir, designed to help understand interpreter concepts and Elixir's pattern matching capabilities.

## Overview

This interpreter implements a small programming language with syntax inspired by Elixir. It demonstrates core interpreter concepts including lexical analysis, parsing, and evaluation while leveraging Elixir's powerful features.

## Features

- Integer arithmetic (`5 + 3 * 2`)
- String operations (`"hello" <> " world"`)
- Boolean expressions (`true`, `false`)
- List manipulation (`[1, 2, 3] |> length()`)
- Functions with closure support
- Pattern matching (`x = 5`)
- Pipe operator (`|>`)
- Built-in functions (`length/1`, `hd/1`, `tl/1`)
- Conditional expressions (`if/else`)

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/elixirlang.git

# Enter the directory
cd elixirlang

# Get dependencies
mix deps.get

# Run tests
mix test
```
````

## Usage

Start the REPL:

```elixir
iex -S mix
iex> Elixirlang.main()
```

### Basic Examples

```elixir
# Arithmetic
╭─ λ 5 + 3 * 2
=> 11

# String concatenation
╭─ λ "Hello" <> " World"
=> "Hello World"

# Pattern matching
╭─ λ x = 5
=> 5
╭─ λ y = x + 3
=> 8

# Lists
╭─ λ [1, 2, 3] |> length()
=> 3

# Functions
╭─ λ def double(x) do
╰─➤   x * 2
╰─➤ end
=> <function>
╭─ λ double(5)
=> 10

# Pipe operator
╭─ λ [1, 2, 3] |> hd()
=> 1
```

## Project Structure

```
lib/
├── elixirlang.ex              # Main module
└── interpreter/
    ├── lexer.ex              # Tokenization
    ├── parser.ex             # AST generation
    ├── evaluator.ex          # Expression evaluation
    ├── environment.ex        # Variable/scope management
    ├── object.ex             # Runtime objects
    ├── token.ex              # Token definitions
    ├── ast.ex                # AST node definitions
    └── repl.ex               # Interactive shell

test/
└── interpreter/              # Comprehensive test suite
```

## Implementation Details

1. **Lexer**: Converts source code into tokens

   ```elixir
   iex> input = "5 + 3"
   iex> lexer = Lexer.new(input)
   # Produces tokens: INT(5), PLUS, INT(3)
   ```

2. **Parser**: Builds Abstract Syntax Tree (AST)

   ```elixir
   iex> parser = Parser.new(lexer)
   iex> {program, _} = Parser.parse_program(parser)
   # Creates AST nodes representing the expression
   ```

3. **Evaluator**: Executes the AST
   ```elixir
   iex> {result, _env} = Evaluator.eval(program)
   iex> result.value  # => 8
   ```

## Key Elixir Features Used

- **Pattern Matching**: Extensively used in parser and evaluator
- **Structs**: For representing tokens, AST nodes, and runtime objects
- **Recursion**: For tree traversal and evaluation
- **Protocols**: For type-specific behavior
- **Immutable Data**: All state changes create new copies

## Additional Notes

- This is an educational implementation focusing on clarity over performance
- Error handling is omitted to maintain focus on core concepts
- The implementation prioritizes readability over optimization
- Built-in functions are limited to demonstrate basic concepts

## Future Enhancements

- Error handling and better error messages
- More built-in functions
- Module system
- Type system
- Standard library
- Documentation improvements

## Testing

Run the comprehensive test suite:

```bash
mix test
```

The test suite covers:

- Lexical analysis
- Parsing
- Evaluation
- Object system
- REPL functionality

## License

MIT License

```

```
