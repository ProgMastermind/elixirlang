defmodule Elixirlang.Parser do
  @moduledoc """
  Converts tokens into an Abstract Syntax Tree (AST).

  The parser implements recursive descent parsing with precedence climbing
  to handle expressions, functions, and control structures.

  Supports:
  - Integer arithmetic
  - String operations
  - Function definitions
  - List operations
  - Pattern matching
  - Pipe operator
  """

  alias Elixirlang.{Token, Lexer, AST}

  @precedences %{
    :MATCH => :EQUALS,
    :EQ => :EQUALS,
    :NOT_EQ => :EQUALS,
    :LT => :LESSGREATER,
    :GT => :LESSGREATER,
    :LTE => :LESSGREATER,
    :GTE => :LESSGREATER,
    :PIPE => :PIPE,
    :PLUS => :SUM,
    :MINUS => :SUM,
    :CONCAT => :SUM,
    :SLASH => :PRODUCT,
    :ASTERISK => :PRODUCT,
    :LPAREN => :CALL
  }

  @precedence_values %{
    :LOWEST => 1,
    :PIPE => 2,
    :EQUALS => 3,
    :LESSGREATER => 4,
    :SUM => 5,
    :PRODUCT => 6,
    :PREFIX => 7,
    :CALL => 8
  }

  defstruct lexer: nil,
            current_token: nil,
            peek_token: nil,
            errors: []

  @doc """
  Creates a new parser instance from a lexer.
  """
  def new(lexer) do
    parser = %__MODULE__{lexer: lexer}

    parser
    |> next_token()
    |> next_token()
  end

  @doc """
  Parses the complete program and returns an AST.
  Returns {program_node, parser_state}.
  """
  def parse_program(parser) do
    program = %AST.Program{statements: []}
    parse_program_statements(parser, program.statements)
  end

  defp parse_program_statements(parser, statements) do
    if parser.current_token.type == Token.eof() do
      {%AST.Program{statements: Enum.reverse(statements)}, parser}
    else
      case parse_statement(parser) do
        {statement, new_parser} ->
          parse_program_statements(
            next_token(new_parser),
            [statement | statements]
          )
      end
    end
  end

  defp parse_statement(parser) do
    case parser.current_token.type do
      :DEF -> parse_function_definition(parser)
      _ -> parse_expression_statement(parser)
    end
  end

  defp parse_function_definition(parser) do
    token = parser.current_token
    parser = next_token(parser)

    unless parser.current_token.type == :IDENT do
      {nil, parser}
    else
      name = parser.current_token
      parser = next_token(parser)

      unless parser.current_token.type == :LPAREN do
        {nil, parser}
      else
        {parameters, parser} = parse_function_parameters(parser)

        unless parser.current_token.type == :DO do
          {nil, parser}
        else
          parser = next_token(parser)
          {body, parser} = parse_block_statement(parser)

          function_literal = %AST.FunctionLiteral{
            token: token,
            parameters: parameters,
            body: body
          }

          # Create a PatternMatchExpression to assign the function to the name
          pattern_match = %AST.PatternMatchExpression{
            token: token,
            left: %AST.Identifier{
              token: name,
              value: name.literal
            },
            right: function_literal
          }

          {pattern_match, parser}
        end
      end
    end
  end

  defp parse_function_parameters(parser) do
    parser = next_token(parser)
    parameters = []

    parse_parameters_list(parser, parameters)
  end

  defp parse_parameters_list(parser, parameters) do
    case parser.current_token.type do
      :RPAREN ->
        {parameters, next_token(parser)}

      :IDENT ->
        param = %AST.Identifier{
          token: parser.current_token,
          value: parser.current_token.literal
        }

        parser = next_token(parser)

        case parser.current_token.type do
          :COMMA ->
            parser = next_token(parser)
            parse_parameters_list(parser, parameters ++ [param])

          :RPAREN ->
            {parameters ++ [param], next_token(parser)}

          _ ->
            {nil, parser}
        end

      _ ->
        {nil, parser}
    end
  end

  defp parse_expression_statement(parser) do
    token = parser.current_token
    {expression, new_parser} = parse_expression(parser, :LOWEST)
    {%AST.ExpressionStatement{token: token, expression: expression}, new_parser}
  end

  defp parse_expression(parser, precedence) do
    {left, new_parser} =
      case parser.current_token.type do
        :INT -> parse_integer_literal(parser)
        :BANG -> parse_prefix_expression(parser)
        :MINUS -> parse_prefix_expression(parser)
        :PLUS -> parse_prefix_expression(parser)
        :TRUE -> parse_boolean_literal(parser)
        :FALSE -> parse_boolean_literal(parser)
        :LPAREN -> parse_grouped_expression(parser)
        :IDENT -> parse_identifier(parser)
        :IF -> parse_if_expression(parser)
        :MATCH -> parse_pattern_match(parser)
        :STRING -> parse_string_literal(parser)
        :LBRACKET -> parse_list_literal(parser)
        _ -> {nil, parser}
      end

    parse_expression_continued(new_parser, left, @precedence_values[precedence])
  end

  defp parse_expression_continued(parser, left, precedence) do
    cond do
      left == nil ->
        {nil, parser}

      precedence >= peek_precedence_value(parser) ->
        {left, parser}

      true ->
        case infix_parse_fn(parser.peek_token.type) do
          nil ->
            {left, parser}

          infix_fn ->
            parser = next_token(parser)
            {new_left, new_parser} = infix_fn.(parser, left)
            parse_expression_continued(new_parser, new_left, precedence)
        end
    end
  end

  defp parse_call_expression(parser, function) do
    token = parser.current_token
    {arguments, parser} = parse_call_arguments(parser)

    {%AST.CallExpression{
       token: token,
       function: function,
       arguments: arguments
     }, parser}
  end

  defp parse_call_arguments(parser) do
    case parser.peek_token.type do
      :RPAREN ->
        # Single next_token
        parser = next_token(parser)
        {[], parser}

      _ ->
        parser = next_token(parser)
        {arg, parser} = parse_expression(parser, :LOWEST)
        parse_arguments_list(parser, [arg])
    end
  end

  defp parse_arguments_list(parser, arguments) do
    case parser.peek_token.type do
      :COMMA ->
        parser = next_token(parser)
        # Keep double next_token for comma case
        parser = next_token(parser)
        {arg, parser} = parse_expression(parser, :LOWEST)
        parse_arguments_list(parser, arguments ++ [arg])

      :RPAREN ->
        # Single next_token
        parser = next_token(parser)
        {arguments, parser}

      _ ->
        {arguments, parser}
    end
  end

  defp parse_integer_literal(parser) do
    {%AST.IntegerLiteral{
       token: parser.current_token,
       value: String.to_integer(parser.current_token.literal)
     }, parser}
  end

  defp parse_boolean_literal(parser) do
    {%AST.BooleanLiteral{
       token: parser.current_token,
       value: parser.current_token.type == :TRUE
     }, parser}
  end

  defp parse_prefix_expression(parser) do
    token = parser.current_token
    operator = parser.current_token.literal

    parser = next_token(parser)
    {right, new_parser} = parse_expression(parser, :PREFIX)

    {%AST.PrefixExpression{
       token: token,
       operator: operator,
       right: right
     }, new_parser}
  end

  defp parse_infix_expression(parser, left) do
    token = parser.current_token
    operator = parser.current_token.literal
    precedence = current_precedence_value(parser)

    parser = next_token(parser)
    {right, new_parser} = parse_expression(parser, get_precedence_name(precedence))

    {%AST.InfixExpression{
       token: token,
       left: left,
       operator: operator,
       right: right
     }, new_parser}
  end

  defp parse_grouped_expression(parser) do
    parser = next_token(parser)
    {exp, parser} = parse_expression(parser, :LOWEST)

    if parser.peek_token.type != :RPAREN do
      {nil, parser}
    else
      {exp, next_token(parser)}
    end
  end

  defp parse_identifier(parser) do
    {%AST.Identifier{
       token: parser.current_token,
       value: parser.current_token.literal
     }, parser}
  end

  defp parse_if_expression(parser) do
    token = parser.current_token
    parser = next_token(parser)

    unless parser.current_token.type == :LPAREN do
      {nil, parser}
    else
      parser = next_token(parser)
      {condition, parser} = parse_expression(parser, :LOWEST)

      unless parser.peek_token.type == :RPAREN do
        {nil, parser}
      else
        parser = next_token(parser)
        parser = next_token(parser)

        unless parser.current_token.type == :DO do
          {nil, parser}
        else
          parser = next_token(parser)
          {consequence, parser} = parse_block_statement(parser)

          {alternative, parser} =
            if parser.current_token.type == :ELSE do
              parser = next_token(parser)
              parse_block_statement(parser)
            else
              {nil, parser}
            end

          {%AST.IfExpression{
             token: token,
             condition: condition,
             consequence: consequence,
             alternative: alternative
           }, parser}
        end
      end
    end
  end

  defp parse_block_statement(parser) do
    token = parser.current_token
    statements = []

    {statements, parser} = collect_block_statements(parser, statements)

    {%AST.BlockStatement{
       token: token,
       statements: statements
     }, parser}
  end

  defp collect_block_statements(parser, statements) do
    case parser.current_token.type do
      :END ->
        {statements, next_token(parser)}

      :ELSE ->
        {statements, parser}

      :EOF ->
        {statements, parser}

      _ ->
        {stmt, new_parser} = parse_expression_statement(parser)

        collect_block_statements(
          next_token(new_parser),
          statements ++ [stmt]
        )
    end
  end

  defp parse_pattern_match(parser) do
    token = parser.current_token
    parser = next_token(parser)
    {right, new_parser} = parse_expression(parser, :LOWEST)

    {%AST.PatternMatchExpression{
       token: token,
       left: nil,
       right: right
     }, new_parser}
  end

  defp parse_pattern_match_infix(parser, left) do
    token = parser.current_token
    precedence = current_precedence_value(parser)
    parser = next_token(parser)
    {right, new_parser} = parse_expression(parser, get_precedence_name(precedence))

    {%AST.PatternMatchExpression{
       token: token,
       left: left,
       right: right
     }, new_parser}
  end

  defp parse_string_literal(parser) do
    {%AST.StringLiteral{
       token: parser.current_token,
       value: parser.current_token.literal
     }, parser}
  end

  defp parse_list_literal(parser) do
    token = parser.current_token
    {elements, new_parser} = parse_list_elements(parser)

    {%AST.ListLiteral{
       token: token,
       elements: elements
     }, new_parser}
  end

  defp parse_list_elements(parser) do
    case parser.peek_token.type do
      :RBRACKET ->
        parser = next_token(parser)
        {[], next_token(parser)}

      _ ->
        parser = next_token(parser)
        {first_element, parser} = parse_expression(parser, :LOWEST)
        parse_element_list(parser, [first_element])
    end
  end

  defp parse_element_list(parser, elements) do
    case parser.peek_token.type do
      :COMMA ->
        # Skip COMMA
        parser = next_token(parser)
        # Move to next element
        parser = next_token(parser)
        {element, parser} = parse_expression(parser, :LOWEST)
        parse_element_list(parser, elements ++ [element])

      :RBRACKET ->
        {elements, next_token(parser)}

      _ ->
        {elements, parser}
    end
  end

  defp parse_pipe_expression(parser, left) do
    token = parser.current_token
    precedence = current_precedence_value(parser)
    parser = next_token(parser)
    {right, new_parser} = parse_expression(parser, get_precedence_name(precedence))

    {%AST.PipeExpression{
       token: token,
       left: left,
       right: right
     }, new_parser}
  end

  defp infix_parse_fn(:LPAREN), do: &parse_call_expression/2

  defp infix_parse_fn(:PIPE), do: &parse_pipe_expression/2

  defp infix_parse_fn(token_type) when token_type == :MATCH do
    &parse_pattern_match_infix/2
  end

  defp infix_parse_fn(token_type)
       when token_type in [
              :PLUS,
              :MINUS,
              :SLASH,
              :ASTERISK,
              :EQ,
              :NOT_EQ,
              :LT,
              :GT,
              :LTE,
              :GTE,
              :CONCAT,
              :RBRACKET
            ] do
    &parse_infix_expression/2
  end

  defp infix_parse_fn(_), do: nil

  defp peek_precedence_value(parser) do
    precedence = Map.get(@precedences, parser.peek_token.type, :LOWEST)
    @precedence_values[precedence]
  end

  defp current_precedence_value(parser) do
    precedence = Map.get(@precedences, parser.current_token.type, :LOWEST)
    @precedence_values[precedence]
  end

  defp get_precedence_name(value) do
    Enum.find(@precedence_values, fn {_k, v} -> v == value end) |> elem(0)
  end

  defp next_token(parser) do
    %{
      parser
      | current_token: parser.peek_token,
        peek_token: elem(Lexer.next_token(parser.lexer), 0),
        lexer: elem(Lexer.next_token(parser.lexer), 1)
    }
  end
end
