defmodule StateMachine.Interpreter do
  @doc """
  This module implements an Amazon States Language interpreter.
  """

  require Logger

  alias StateMachine.StatesLanguage
  alias StateMachine.Context
  alias StateMachine.Machine

  def start_execution(user_context, resource_handler, state_machine, args) do
    ctx = Context.create(user_context, resource_handler)
    Logger.debug("Start execution #{inspect ctx}")
    Machine.start(state_machine, ctx, args)
  end

  def resume_execution(user_context, resource_handler, state_machine, state_name, state_args, result) do
    ctx = Context.create(user_context, resource_handler)
    Logger.debug("Resume execution #{inspect state_name} #{inspect state_args} #{inspect result}")
    Machine.resume(state_machine, state_name, ctx, state_args, result)
  end

  def state_machine_valid?(definition) do
    with :ok <- StatesLanguage.validate(definition),
         {:ok, _} <- Machine.parse(definition) do
      true
    else
      _ -> false
    end
  end
end
