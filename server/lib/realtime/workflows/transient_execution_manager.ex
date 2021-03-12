defmodule Realtime.Workflows.TransientExecutionManager do

  alias StateMachine.Interpreter
  alias StateMachine.Machine
  alias Realtime.Workflows.Context

  require Logger

  defmodule ResourceHandler do
    alias StateMachine.ResourceHandler

    use ResourceHandler

    @impl ResourceHandler
    def handle_task(_state, _ctx, args) do
      Logger.info("Task #{inspect args}")
      {:ok, args}
    end
  end

  def start_workflow_execution(workflow, execution, opts \\ []) do
    with {:ok, machine} = Machine.parse(workflow.definition) do
      Task.Supervisor.start_child(
        __MODULE__,
        fn () ->
          ctx = Context.create(workflow, execution, opts)
          result = Interpreter.start_execution(ctx, ResourceHandler, machine, execution.arguments)
          if ctx.reply_to != nil do
            send ctx.reply_to, result
          end
        end
      )
    end
  end
end
