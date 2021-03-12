defmodule StateMachine.StateTest do
  use ExUnit.Case
  import Mock

  alias StateMachine.Context
  alias StateMachine.State

  @simple_args %{
    "Name" => "Name",
    "Time" => 2
  }

  @ctx Context.create(%{}, nil)

  describe "Fail state" do
    test "returns failure" do
      {:ok, state} = State.parse(%{
        "Type" => "Fail",
        "Error" => "My Error",
        "Cause" => "Human readable message here"
      })

      {:failure, error} = State.handle_state(state, @ctx, @simple_args)
      assert error.name == "My Error"
      assert error.cause == "Human readable message here"
    end
  end

  describe "Succeed state" do
    test "returns its args by default" do
      {:ok, state} = State.parse(%{
        "Type" => "Succeed"
      })

      {:success, @simple_args} = State.handle_state(state, @ctx, @simple_args)
    end
  end

  describe "Choice state" do
    test "transitions to a state based on its input" do
      {:ok, state} = State.parse(%{
        "Type" => "Choice",
        "Default" => "RecordEvent",
        "Choices" => [%{
          "Next" => "Public",
          "Not" => %{
            "Variable" => "$.type",
            "StringEquals" => "Private"
          }
        }, %{
          "Next" => "ValueInTwenties",
          "And" => [%{
            "Variable" => "$.value",
            "IsPresent" => true
          }, %{
            "Variable" => "$.value",
            "IsNumeric" => true
          }, %{
            "Variable" => "$.value",
            "NumericGreaterThanEquals" => 20
          }, %{
            "Variable" => "$.value",
            "NumericLessThan" => 30
          }]
        }]
      })

      args = %{
        "type" => "Private",
        "value" => 22
      }

      {:continue, "ValueInTwenties", _} = State.handle_state(state, @ctx, args)
    end
  end

  describe "Wait state" do
    defmodule WaitHandler do
      def handle_wait(_state, _wait, _ctx, _args) do
      end
    end

    test "delegates to the resource handler" do
      with_mock WaitHandler, [handle_wait: fn(_, _, _, _) -> {:ok, %{"Result" => "Mocked"}} end] do
        ctx = Context.create(%{"run_id" => "123"}, WaitHandler)
        {:ok, state} = State.parse(%{
          "Type" => "Wait",
          "Next" => "FooBar",
          "SecondsPath" => "$.Time"
        })

        {:continue, "FooBar", %{"Result" => "Mocked"}} = State.handle_state(state, ctx, @simple_args)
        assert called WaitHandler.handle_wait(:_, {:seconds, 2}, %{"run_id" => "123"}, @simple_args)
      end
    end
  end

  describe "Pass state" do
    test "returns its args if terminal" do
      {:ok, state} = State.parse(%{
        "Type" => "Pass",
        "End" => true
      })

      {:success, @simple_args} = State.handle_state(state, @ctx, @simple_args)
    end

    test "returns its args and next state name" do
      {:ok, state} = State.parse(%{
        "Type" => "Pass",
        "Next" => "Next State"
      })

      {:continue, "Next State", @simple_args} = State.handle_state(state, @ctx, @simple_args)
    end

    test "returns error if no Next or End" do
      {:error, _} = State.parse(%{
        "Type" => "Pass"
      })
    end
  end

  describe "Map state" do
  end

  describe "Parallel state" do
  end

  describe "Task state" do
    defmodule TaskHandler do
      def handle_task(_state, _ctx, _args) do
      end
    end

    test "delegates to the resource handler" do
      with_mock TaskHandler, [handle_task: fn(_, _, _) -> {:ok, %{"Result" => "Mocked"}} end] do
        ctx = Context.create(%{"run_id" => "123"}, TaskHandler)
        {:ok, state} = State.parse(%{
          "Type" => "Task",
          "Resource" => "TestResource",
          "Next" => "FooBar"
        })

        {:continue, "FooBar", %{"Result" => "Mocked"}} = State.handle_state(state, ctx, @simple_args)
        assert called TaskHandler.handle_task(:_, %{"run_id" => "123"}, @simple_args)
      end
    end
  end

end
