defmodule StateMachine.PayloadTemplateTest do
  use ExUnit.Case

  alias StateMachine.PayloadTemplate

  describe "apply" do
    @args %{
      "flagged" => 7,
      "values" => [0, 10, 20, 30, 40, 50]
    }

    @ctx %{
      "DayOfWeek" => "TUESDAY"
    }

    test "returns the template when no processing directive" do
      template = %{
        "first" => 89,
        "second" => 99
      }
      {:ok, result} = PayloadTemplate.apply(template, @ctx, @args)
      assert result == template
    end

    test "returns the input when the template is nil" do
      {:ok, result} = PayloadTemplate.apply(nil, @ctx, @args)
      assert result == @args
    end

    test "returns error if the template is not a map" do
      {:error, _} = PayloadTemplate.apply([], @ctx, @args)
    end

    test "transforms fields that end with .$" do
      template = %{
        "flagged" => true,
        "parts" => %{
          "first.$" => "$.values[0]",
          "last3.$" => "$.values[3:]"
        },
        "weekday.$" => "$$.DayOfWeek",
        "formattedOutput.$" => "States.Format('Today is {}', $$.DayOfWeek)"
      }
      expected = %{
        "flagged" => true,
        "parts" => %{
          "first" => 0,
          "last3" => [30, 40, 50]
        },
        "weekday" => "TUESDAY",
        "formattedOutput" => "Today is TUESDAY"
      }
      {:ok, result} = PayloadTemplate.apply(template, @ctx, @args)
      assert result == expected
    end
  end
end
