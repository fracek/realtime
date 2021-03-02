defmodule StateMachine.RuleTest do
  use ExUnit.Case

  alias StateMachine.Rule

  describe "create" do
    test "returns error if Next field is missing" do
      {:error, _} = Rule.create(%{})
    end

    test "returns a rule if syntax is correct" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "StringEquals" => "abc", "Variable" => "$.foo"})
      assert rule.next == "My State"
    end
  end

  describe "Or" do
    test "returns true if any inner rule returns true" do
      rules = [
        %{"StringEquals" => "abc", "Variable" => "$.foo"},
        %{"StringEquals" => "xyz", "Variable" => "$.foo"},
      ]
      {:ok, rule} = Rule.create(%{"Next" => "My State", "Or" => rules})
      assert Rule.call(rule, %{"foo" => "xyz"})
    end

    test "returns false if no inner rule returns true" do
      rules = [
        %{"StringEquals" => "abc", "Variable" => "$.foo"},
        %{"StringEquals" => "xyz", "Variable" => "$.foo"},
      ]
      {:ok, rule} = Rule.create(%{"Next" => "My State", "Or" => rules})
      assert not Rule.call(rule, %{"foo" => "nope"})
    end
  end

  describe "And" do
    test "returns true if all inner rule returns true" do
      rules = [
        %{"IsPresent" => true, "Variable" => "$.foo"},
        %{"IsNumeric" => true, "Variable" => "$.foo"},
        %{"NumericGreaterThan" => 100, "Variable" => "$.foo"},
      ]
      {:ok, rule} = Rule.create(%{"Next" => "My State", "And" => rules})
      assert Rule.call(rule, %{"foo" => 200})
    end

    test "returns false if any inner rule returns false" do
      rules = [
        %{"IsPresent" => true, "Variable" => "$.foo"},
        %{"IsNumeric" => true, "Variable" => "$.foo"},
        %{"NumericGreaterThan" => 100, "Variable" => "$.foo"},
      ]
      {:ok, rule} = Rule.create(%{"Next" => "My State", "And" => rules})
      assert not Rule.call(rule, %{"foo" => 100})
    end
  end

  describe "Not" do
    test "returns true if the inner returns false" do
        {:ok, rule} = Rule.create(%{"Next" => "My State", "Not" => %{"NumericEquals" => 100, "Variable" => "$.foo"}})
        assert Rule.call(rule, %{"foo" => 200})
    end

    test "returns false if the inner returns true" do
        {:ok, rule} = Rule.create(%{"Next" => "My State", "Not" => %{"NumericEquals" => 200, "Variable" => "$.foo"}})
        assert not Rule.call(rule, %{"foo" => 200})
    end
  end

  describe "String" do
    @comparison [
      {"StringEquals", "abc", "abc", true},
      {"StringEquals", "abc", "xyz", false},

      {"StringLessThan", "bbb", "abc", true},
      {"StringLessThan", "aaa", "abc", false},

      {"StringGreaterThan", "abc", "bbb", true},
      {"StringGreaterThan", "abc", "aaa", false},

      {"StringLessThanEquals", "bbb", "abc", true},
      {"StringLessThanEquals", "abc", "abc", true},
      {"StringLessThanEquals", "aaa", "abc", false},

      {"StringGreaterThanEquals", "abc", "bbb", true},
      {"StringGreaterThanEquals", "abc", "abc", true},
      {"StringGreaterThanEquals", "abc", "aaa", false},
    ]

    test "returns comparison value" do
      Enum.each(@comparison, fn {op, value, var, expected} ->
        {:ok, rule} = Rule.create(%{"Next" => "My State", op => value, "Variable" => "$.foo"})
        assert(expected == Rule.call(rule, %{"foo" => var}), inspect {op, value, var, expected})

        {:ok, rule} = Rule.create(%{"Next" => "My State", (op <> "Path") => "$.bar", "Variable" => "$.foo"})
        assert(expected == Rule.call(rule, %{"foo" => var, "bar" => value}), inspect {op, value, var, expected})
      end)
    end

    test "returns false if type is not string" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "StringEquals" => 1, "Variable" => "$.foo"})
      assert not Rule.call(rule, %{"foo" => 1})
    end
  end

  describe "Numeric" do
    @comparison [
      {"NumericEquals", 100, 100, true},
      {"NumericEquals", 100, 200, false},

      {"NumericLessThan", 200, 100, true},
      {"NumericLessThan", 100, 200, false},

      {"NumericGreaterThan", 100, 200, true},
      {"NumericGreaterThan", 200, 100, false},

      {"NumericLessThanEquals", 200, 100, true},
      {"NumericLessThanEquals", 100, 100, true},
      {"NumericLessThanEquals", 100, 200, false},

      {"NumericGreaterThanEquals", 100, 200, true},
      {"NumericGreaterThanEquals", 100, 100, true},
      {"NumericGreaterThanEquals", 200, 100, false},
    ]

    test "returns comparison value" do
      Enum.each(@comparison, fn {op, value, var, expected} ->
        {:ok, rule} = Rule.create(%{"Next" => "My State", op => value, "Variable" => "$.foo"})
        assert(expected == Rule.call(rule, %{"foo" => var}), inspect {op, value, var, expected})

        {:ok, rule} = Rule.create(%{"Next" => "My State", (op <> "Path") => "$.bar", "Variable" => "$.foo"})
        assert(expected == Rule.call(rule, %{"foo" => var, "bar" => value}), inspect {op, value, var, expected})
      end)
    end

    test "returns false if type is not a number" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "NumericEquals" => "abc", "Variable" => "$.foo"})
      assert not Rule.call(rule, %{"foo" => "abc"})
    end
  end

  describe "Boolean" do
    @comparison [
      {"BooleanEquals", false, false, true},
      {"BooleanEquals", true, false, false},
    ]

    test "returns comparison value" do
      Enum.each(@comparison, fn {op, value, var, expected} ->
        {:ok, rule} = Rule.create(%{"Next" => "My State", op => value, "Variable" => "$.foo"})
        assert(expected == Rule.call(rule, %{"foo" => var}), inspect {op, value, var, expected})

        {:ok, rule} = Rule.create(%{"Next" => "My State", (op <> "Path") => "$.bar", "Variable" => "$.foo"})
        assert(expected == Rule.call(rule, %{"foo" => var, "bar" => value}), inspect {op, value, var, expected})
      end)
    end

    test "returns false if type is not a boolean" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "BooleanEquals" => "abc", "Variable" => "$.foo"})
      assert not Rule.call(rule, %{"foo" => "abc"})
    end
  end

  describe "Timestamp" do
    @comparison [
      {"TimestampEquals", "2016-03-14T01:59:00Z", "2016-03-14T01:59:00Z", true},
      {"TimestampEquals", "2016-03-14T01:59:00Z", "2020-03-14T03:59:00Z", false},

      {"TimestampLessThan", "2020-03-14T03:59:00Z", "2016-03-14T01:59:00Z", true},
      {"TimestampLessThan", "2016-03-14T01:59:00Z", "2020-03-14T03:59:00Z", false},

      {"TimestampGreaterThan", "2016-03-14T01:59:00Z", "2020-03-14T03:59:00Z", true},
      {"TimestampGreaterThan", "2020-03-14T03:59:00Z", "2016-03-14T01:59:00Z", false},

      {"TimestampLessThanEquals", "2020-03-14T03:59:00Z", "2016-03-14T01:59:00Z", true},
      {"TimestampLessThanEquals", "2016-03-14T01:59:00Z", "2016-03-14T01:59:00Z", true},
      {"TimestampLessThanEquals", "2016-03-14T01:59:00Z", "2020-03-14T03:59:00Z", false},

      {"TimestampGreaterThanEquals", "2016-03-14T01:59:00Z", "2020-03-14T03:59:00Z", true},
      {"TimestampGreaterThanEquals", "2016-03-14T01:59:00Z", "2016-03-14T01:59:00Z", true},
      {"TimestampGreaterThanEquals", "2020-03-14T03:59:00Z", "2016-03-14T01:59:00Z", false},
    ]

    test "returns comparison value" do
      Enum.each(@comparison, fn {op, value, var, expected} ->
        {:ok, rule} = Rule.create(%{"Next" => "My State", op => value, "Variable" => "$.foo"})
        assert(expected == Rule.call(rule, %{"foo" => var}), inspect {op, value, var, expected})

        {:ok, rule} = Rule.create(%{"Next" => "My State", (op <> "Path") => "$.bar", "Variable" => "$.foo"})
        assert(expected == Rule.call(rule, %{"foo" => var, "bar" => value}), inspect {op, value, var, expected})
      end)
    end

    test "returns false if type is not a timestamp" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "TimestampEquals" => "abc", "Variable" => "$.foo"})
      assert not Rule.call(rule, %{"foo" => "abc"})
    end
  end

  describe "IsNull" do
    test "returns true if the value is present and null" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsNull" => true, "Variable" => "$.foo"})
      assert Rule.call(rule, %{"foo" => nil})
    end

    test "returns false if the value is not present" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsNull" => true, "Variable" => "$.foo"})
      assert not Rule.call(rule, %{"bar" => nil})
    end

    test "returns false if the value present but not null" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsNull" => true, "Variable" => "$.foo"})
      assert not Rule.call(rule, %{"foo" => "not null"})
    end
  end

  describe "IsPresent" do
    test "returns true if the value is present and not null" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsPresent" => true, "Variable" => "$.foo"})
      assert Rule.call(rule, %{"foo" => "not null"})
    end

    test "returns true if the value is present and null" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsPresent" => true, "Variable" => "$.foo"})
      assert Rule.call(rule, %{"foo" => nil})
    end

    test "returns false if the value is not present" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsPresent" => true, "Variable" => "$.foo"})
      assert not Rule.call(rule, %{"bar" => nil})
    end
  end

  describe "IsString" do
    test "returns true if the value is a string" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsString" => true, "Variable" => "$.foo"})
      assert Rule.call(rule, %{"foo" => "a string"})
    end

    test "returns false if the value is not a string" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsString" => true, "Variable" => "$.foo"})
      assert not Rule.call(rule, %{"foo" => 100})
    end
  end

  describe "IsNumeric" do
    test "returns true if the value is a number" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsNumeric" => true, "Variable" => "$.foo"})
      assert Rule.call(rule, %{"foo" => 100})
    end

    test "returns false if the value is not a number" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsNumeric" => true, "Variable" => "$.foo"})
      assert not Rule.call(rule, %{"foo" => "not a number"})
    end
  end

  describe "IsBoolean" do
    test "returns true if the value is a boolean" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsBoolean" => true, "Variable" => "$.foo"})
      assert Rule.call(rule, %{"foo" => false})
    end

    test "returns false if the value is not a boolean" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsBoolean" => true, "Variable" => "$.foo"})
      assert not Rule.call(rule, %{"foo" => "not a boolean"})
    end
  end

  describe "IsTimestamp" do
    test "returns true if the value is a timestamp" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsTimestamp" => true, "Variable" => "$.foo"})
      assert Rule.call(rule, %{"foo" => "2020-03-14T03:59:00Z"})
    end

    test "returns false if the value is not a timestamp" do
      {:ok, rule} = Rule.create(%{"Next" => "My State", "IsTimestamp" => true, "Variable" => "$.foo"})
      assert not Rule.call(rule, %{"foo" => "not a timestamp"})
    end
  end

end
