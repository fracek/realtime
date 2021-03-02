defmodule Realtime.Workflows.TransientExecutionManager do

  alias StateMachine.Interpreter
  alias StateMachine.Context
  require Logger

  def start_workflow_execution(workflow, execution, opts \\ []) do
    Task.Supervisor.start_child(
      __MODULE__,
      fn () ->
        ctx = Context.create(workflow, execution, opts)
        Interpreter.start_execution(ctx, workflow.definition)
      end
    )
  end
end
