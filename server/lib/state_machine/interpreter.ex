defmodule StateMachine.Interpreter do
  @doc """
  This module implements an Amazon States Language interpreter.
  """

  require Logger

  alias StateMachine.StatesLanguage

  def start_execution(context, state_machine) do
    Logger.debug("Start execution #{inspect context}")
    Logger.debug("State Machine #{inspect state_machine}")
    :ok
  end

  def state_machine_valid?(definition) do
    case StatesLanguage.validate(definition) do
      :ok -> true
      err ->
        Logger.debug("Invalid: #{inspect err}")
        false
    end
  end

  def handle_state(state_machine, ctx, state_name, args) when is_binary(state_name) do
    state = state_machine["States"][state_name]
    handle_state(state_machine, ctx, state, args)
  end

  def handle_state(state_machine, ctx, %{"Type" => "Fail"} = state, _args) do
    error = state["Error"]
    cause = state["Cause"]
    error = StateMachine.Error.create(error, cause)
    {:failure, error}
  end

  def handle_state(state_machine, ctx, %{"Type" => "Succeed"}, args) do
    {:success, args}
  end

  def handle_state(state_machine, ctx, %{"Type" => "Pass"} = state, args) do
    continue_with_result(state, args)
  end

  def handle_state(state_machine, ctx, %{"Type" => "Choice"} = state, args) do
    continue_with_result(state, args)
  end

  def handle_state(state_machine, ctx, state, args) do
    Logger.error("Unhandled state #{inspect state} with args #{inspect args}")
    {:error, "Unhandled state"}
  end

  defp continue_with_result(state, result) do
    case state["End"] do
      true -> {:success, result}
      _ ->
        case state["Next"] do
          nil -> {:error, "State must have one of End or Next"}
          next -> {:continue, next, result}
        end
    end
  end
end
