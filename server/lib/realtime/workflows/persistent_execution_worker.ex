defmodule Realtime.Workflows.PersistentExecutionWorker do
  use Oban.Worker, queue: :workflow_interpreter

  require Logger

  alias Realtime.Workflows.Manager
  alias Realtime.Workflows
  alias StateMachine.Context
  alias StateMachine.Interpreter

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    workflow_id = args["workflow_id"]
    execution_id = args["execution_id"]

    workflow = Manager.workflow_by_id(workflow_id)
    {:ok, execution} = Workflows.get_workflow_execution(execution_id)

    ctx = Context.create(workflow, execution)
    Interpreter.start_execution(ctx, workflow.definition)
    :ok
  end
end
