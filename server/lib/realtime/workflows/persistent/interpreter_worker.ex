defmodule Realtime.Workflows.Persistent.InterpreterWorker do
  @moduledoc false

  use Oban.Worker, queue: :workflow_interpreter

  require Logger

  alias Realtime.Workflows.Context
  alias Realtime.Workflows.Persistent.ResourceHandler
  alias Realtime.Workflows

  alias StateMachine.Interpreter
  alias StateMachine.Machine

  @impl Oban.Worker
  def perform(%Oban.Job{args: args} = job) do
    with {:ok, execution} <- Workflows.get_workflow_execution(args["execution_id"]),
         {:ok, workflow} <- Workflows.get_workflow(args["workflow_id"]),
         {:ok, machine} <- Machine.parse(workflow.definition) do
      ctx = Context.create(workflow, execution, args["state_path"])
      result = Interpreter.start_execution(ctx, ResourceHandler, machine, execution.arguments)
      Logger.debug("Persistent.InterpreterWorker: finished with #{inspect result}")
    else
      err ->
        Logger.debug("Persistent.InterpreterWorker: error #{inspect err}")
    end
  end
end
