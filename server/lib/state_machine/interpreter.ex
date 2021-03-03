defmodule StateMachine.Interpreter do
  @doc """
  This module implements an Amazon States Language interpreter.
  """

  require Logger

  alias StateMachine.StatesLanguage
  alias StateMachine.State

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
    handle_state(state_machine, ctx, state_name, state, args)
  end

  def handle_state(state_machine, ctx, state_name, %{"Type" => "Fail"} = state, args),
      do: State.Fail.handle_state(state_machine, ctx, state_name, state, args)

  def handle_state(state_machine, ctx, state_name, %{"Type" => "Succeed"} = state, args),
      do: State.Succeed.handle_state(state_machine, ctx, state_name, state, args)

  def handle_state(state_machine, ctx, state_name, %{"Type" => "Pass"} = state, args),
      do: State.Pass.handle_state(state_machine, ctx, state_name, state, args)

  def handle_state(state_machine, ctx, state_name, %{"Type" => "Choice"} = state, args),
      do: State.Choice.handle_state(state_machine, ctx, state_name, state, args)

  def handle_state(state_machine, ctx, state_name, state, args) do
    Logger.error("Unhandled state #{inspect state_name} #{inspect state} with args #{inspect args}")
    {:error, "Unhandled state"}
  end
end
