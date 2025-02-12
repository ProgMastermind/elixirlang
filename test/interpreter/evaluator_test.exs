defmodule Elixirlang.EvaluatorTest do
  use ExUnit.Case
  alias Elixirlang.{Lexer, Parser, Evaluator, Object, Environment}

  describe "integer evaluation" do
    test "evaluates integer expressions" do
      tests = [
        {"5", 5},
        {"10", 10},
        {"999", 999}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)
        assert_integer_object(evaluated, expected)
      end)
    end
  end

  describe "boolean evaluation" do
    test "evaluates boolean expressions" do
      tests = [
        {"true", true},
        {"false", false}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)
        assert_boolean_object(evaluated, expected)
      end)
    end
  end

  describe "prefix expressions" do
    test "evaluates bang operator" do
      tests = [
        {"!true", false},
        {"!false", true},
        {"!!true", true},
        {"!!false", false}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)
        assert_boolean_object(evaluated, expected)
      end)
    end

    test "evaluates minus operator" do
      tests = [
        {"-5", -5},
        {"-10", -10},
        {"--5", 5}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)
        assert_integer_object(evaluated, expected)
      end)
    end

    test "evaluates plus operator" do
      tests = [
        {"+5", 5},
        {"+10", 10}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)
        assert_integer_object(evaluated, expected)
      end)
    end
  end

  describe "infix expressions" do
    test "evaluates integer operations" do
      tests = [
        {"5 + 5", 10},
        {"5 - 5", 0},
        {"5 * 5", 25},
        {"5 / 5", 1},
        {"50 / 2 * 2 + 10", 60},
        {"2 * 2 * 2 * 2", 16},
        {"5 * 2 + 10", 20},
        {"5 + 2 * 10", 25}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)
        assert_integer_object(evaluated, expected)
      end)
    end

    test "evaluates integer comparisons" do
      tests = [
        {"5 < 6", true},
        {"5 > 6", false},
        {"5 == 5", true},
        {"5 != 5", false},
        {"5 >= 5", true},
        {"5 <= 4", false}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)
        assert_boolean_object(evaluated, expected)
      end)
    end

    test "evaluates boolean operations" do
      tests = [
        {"true == true", true},
        {"false == false", true},
        {"true == false", false},
        {"true != false", true},
        {"false != true", true}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)
        assert_boolean_object(evaluated, expected)
      end)
    end
  end

  describe "if expressions" do
    test "evaluates if expressions" do
      tests = [
        {"if (true) do 10 end", 10},
        {"if (false) do 10 end", nil},
        {"if (1) do 10 end", 10},
        {"if (1 < 2) do 10 end", 10},
        {"if (1 > 2) do 10 end", nil},
        {"if (1 < 2) do 10 else 20 end", 10},
        {"if (1 > 2) do 10 else 20 end", 20}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)

        case expected do
          nil -> assert evaluated == nil
          value when is_integer(value) -> assert_integer_object(evaluated, value)
        end
      end)
    end
  end

  describe "pattern matching" do
    test "evaluates pattern matching expressions" do
      tests = [
        {"x = 5", 5},
        {"x = 5; x", 5},
        {"x = 5; y = x; y", 5},
        {"x = 5; y = x; x = 10; y", 5},
        {"x = 5 + 5", 10},
        {"x = 5; y = x + 5", 10}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)
        assert_integer_object(evaluated, expected)
      end)
    end
  end

  describe "function evaluation" do
    test "evaluates function definition" do
      input = """
      def add(x, y) do
        x + y
      end
      """

      {evaluated, _env} = eval(input)
      assert %Object.Function{} = evaluated
      assert length(evaluated.parameters) == 2
    end

    test "evaluates function calls" do
      tests = [
        {"def double(x) do x * 2 end; double(5)", 10},
        {"def add(x, y) do x + y end; add(5, 5)", 10},
        {"def identity(x) do x end; identity(5)", 5}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)
        assert_integer_object(evaluated, expected)
      end)
    end

    test "ensures proper closure behavior" do
      input = """
      x = 5;
      def closure(y) do
        x + y
      end;
      x = 10;
      closure(5)
      """

      {evaluated, _env} = eval(input)
      assert_integer_object(evaluated, 10)
    end
  end

  describe "string evaluation" do
    test "evaluates string literals" do
      tests = [
        {~s("hello"), "hello"},
        {~s("world"), "world"},
        {~s("hello world"), "hello world"}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)
        assert_string_object(evaluated, expected)
      end)
    end

    defp assert_string_object(object, expected) do
      assert %Object.String{} = object
      assert object.value == expected
    end
  end

  test "evaluates string concatenation" do
    tests = [
      {~s("Hello" <> " World"), "Hello World"},
      {~s("foo" <> "bar"), "foobar"},
      {~s("a" <> "b" <> "c"), "abc"}
    ]

    Enum.each(tests, fn {input, expected} ->
      {evaluated, _env} = eval(input)
      assert_string_object(evaluated, expected)
    end)
  end

  test "evaluates string comparisons" do
    tests = [
      {~s("hello" == "hello"), true},
      {~s("hello" != "world"), true},
      {~s("foo" == "foo"), true},
      {~s("foo" != "foo"), false}
    ]

    Enum.each(tests, fn {input, expected} ->
      {evaluated, _env} = eval(input)
      assert_boolean_object(evaluated, expected)
    end)
  end

  describe "list evaluation" do
    test "evaluates list literals" do
      tests = [
        {"[]", []},
        {"[1, 2, 3]", [1, 2, 3]},
        {"[1 + 2, 3 * 4]", [3, 12]}
      ]

      Enum.each(tests, fn {input, expected} ->
        {evaluated, _env} = eval(input)
        assert_list_object(evaluated, expected)
      end)
    end

    defp assert_list_object(object, expected) do
      assert %Object.List{} = object
      assert Enum.map(object.elements, fn elem -> elem.value end) == expected
    end
  end

  test "evaluates pipe expressions" do
    tests = [
      {"def double(x) do x * 2 end; 5 |> double()", 10},
      {"def add(x, y) do x + y end; 5 |> add(3)", 8}
    ]

    Enum.each(tests, fn {input, expected} ->
      {evaluated, _env} = eval(input)
      assert_integer_object(evaluated, expected)
    end)
  end

  defp eval(input) do
    lexer = Lexer.new(input)
    parser = Parser.new(lexer)
    {program, _} = Parser.parse_program(parser)
    Evaluator.eval(program, Environment.new())
  end

  defp assert_integer_object(object, expected) do
    assert %Object.Integer{} = object
    assert object.value == expected
  end

  defp assert_boolean_object(object, expected) do
    assert %Object.Boolean{} = object
    assert object.value == expected
  end
end
