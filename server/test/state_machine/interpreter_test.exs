defmodule StateMachine.InterpreterTest do
  use ExUnit.Case

  alias StateMachine.Interpreter

  @simple_args %{
    "Name" => "Name"
  }

  describe "Fail state" do
    test "returns failure" do
      machine = %{
        "StartAt" => "Start State",
        "States" => %{
          "Start State" => %{
            "Type" => "Fail",
            "Error" => "My Error",
            "Cause" => "Human readable message here"
          }
        }
      }

      {:failure, error} = Interpreter.handle_state(machine, %{}, "Start State", @simple_args)
      assert error.name == "My Error"
      assert error.cause == "Human readable message here"
    end
  end

  describe "Succeed state" do
    test "returns its args by default" do
      machine = %{
        "StartAt" => "Start State",
        "States" => %{
          "Start State" => %{
            "Type" => "Succeed"
          }
        }
      }

      {:success, @simple_args} = Interpreter.handle_state(machine, %{}, "Start State", @simple_args)
    end
  end

  describe "Choice state" do
  end

  describe "Wait state" do
  end

  describe "Pass state" do
    test "returns its args if terminal" do
      machine = %{
        "StartAt" => "Start State",
        "States" => %{
          "Start State" => %{
            "Type" => "Pass",
            "End" => true
          }
        }
      }

      {:success, @simple_args} = Interpreter.handle_state(machine, %{}, "Start State", @simple_args)
    end

    test "returns its args and next state name" do
      machine = %{
        "StartAt" => "Start State",
        "States" => %{
          "Start State" => %{
            "Type" => "Pass",
            "Next" => "Next State"
          }
        }
      }

      {:continue, "Next State", @simple_args} = Interpreter.handle_state(machine, %{}, "Start State", @simple_args)
    end

    test "returns error if no Next or End" do
      machine = %{
        "StartAt" => "Start State",
        "States" => %{
          "Start State" => %{
            "Type" => "Pass"
          }
        }
      }

      {:error, _} = Interpreter.handle_state(machine, %{}, "Start State", @simple_args)
    end

  end

  describe "Map state" do
  end

  describe "Parallel state" do
  end

  describe "Task state" do
  end
end
