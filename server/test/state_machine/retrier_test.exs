defmodule StateMachine.RetrierTest do
  use ExUnit.Case

  alias StateMachine.Retrier

  describe "create" do
    test "valid retrier with defaults" do
      {:ok, _retrier} = Retrier.create(%{"ErrorEquals" => ["States.Timeout"]})
    end

    test "valid retrier with non default values" do
      {:ok, retrier} = Retrier.create(
        %{
          "ErrorEquals" => ["States.Timeout"],
          "IntervalSeconds" => 3,
          "MaxAttempts" => 2,
          "BackoffRate" => 1.5
        }
      )

      assert retrier.error_equals == ["States.Timeout"]
      assert retrier.interval_seconds == 3
      assert retrier.max_attempts == 2
      assert retrier.backoff_rate == 1.5
      assert retrier.attempt == 0
    end

    test "must contain ErrorEquals field" do
      {:error, _} = Retrier.create(%{"ErrorEquals" => []})
    end

    test "ErrorEquals must be non empty" do
      {:error, _} = Retrier.create(%{})
    end

    test "IntervalSeconds must be integer" do
      {:error, _} = Retrier.create(%{"ErrorEquals" => ["States.Timeout"], "IntervalSeconds" => 1.3})
    end

    test "IntervalSeconds must be positive" do
      {:error, _} = Retrier.create(%{"ErrorEquals" => ["States.Timeout"], "IntervalSeconds" => 0})
    end

    test "MaxAttempts must be integer" do
      {:error, _} = Retrier.create(%{"ErrorEquals" => ["States.Timeout"], "MaxAttempts" => 1.5})
    end

    test "MaxAttempts must be non-negative" do
      {:error, _} = Retrier.create(%{"ErrorEquals" => ["States.Timeout"], "MaxAttempts" => -2})
    end

    test "MaxAttempts can be 0" do
      {:ok, _} = Retrier.create(%{"ErrorEquals" => ["States.Timeout"], "MaxAttempts" => 0})
    end

    test "BackoffRate must be greater than 1.0" do
      {:error, _} = Retrier.create(%{"ErrorEquals" => ["States.Timeout"], "BackoffRate" => 0.5})
    end

    test "BackoffRate can be 1.0" do
      {:ok, _} = Retrier.create(%{"ErrorEquals" => ["States.Timeout"], "BackoffRate" => 1.0})
    end
  end

  describe "next" do
    test "returns the wait time in seconds" do
      {:ok, retrier} = Retrier.create(
        %{
          "ErrorEquals" => ["States.Timeout"],
          "IntervalSeconds" => 3,
          "MaxAttempts" => 2,
          "BackoffRate" => 1.5
        }
      )
      {:wait, 3.0, retrier} = Retrier.next(retrier)
      {:wait, 4.5, retrier} = Retrier.next(retrier)
      {:max_attempts, _} = Retrier.next(retrier)
    end
  end
end
