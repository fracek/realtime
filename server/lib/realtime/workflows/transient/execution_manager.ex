defmodule Realtime.Workflows.Transient.ExecutionManager do
  @moduledoc false

  alias StateMachine.Interpreter
  alias StateMachine.Machine
  alias Realtime.Workflows.Context
  alias Realtime.Workflows.Transient.ResourceHandler

  require Logger

  def start_workflow_execution(workflow, execution, opts \\ []) do
    with {:ok, machine} = Machine.parse(workflow.definition) do
      Task.Supervisor.start_child(
        __MODULE__,
        fn () ->
          ctx = Context.create(workflow, execution, opts)
          result = Interpreter.start_execution(ctx, ResourceHandler, machine, execution.arguments)
          Logger.debug("Transient execution finished: #{inspect result}")
          if ctx.reply_to != nil do
            send ctx.reply_to, result
          end
        end
      )
    end
  end
end
