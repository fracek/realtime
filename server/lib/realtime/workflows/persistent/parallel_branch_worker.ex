defmodule Realtime.Workflows.Persistent.ParallelBranchWorker do
  @moduledoc false

  alias Realtime.Workflows.Context
  alias Realtime.Workflows.Persistent.ResourceHandler
  alias Realtime.Workflows
  alias StateMachine.Interpreter
  alias StateMachine.Machine

  require Logger

  use Oban.Worker, queue: :workflow_interpreter

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, meta: meta} = job) do
    Logger.debug("Resume parallel #{inspect args}")
    with {:ok, execution} <- Workflows.get_workflow_execution(args["execution_id"]),
         {:ok, workflow} <- Workflows.get_workflow(args["workflow_id"]),
         {:ok, machine} <- Machine.parse(workflow.definition),
         {:ok, branch} <- get_branch_machine(machine, args["state_name"], args["branch_index"]) do
      user_ctx = Context.create(workflow, execution, args["state_path"])
      ctx = StateMachine.Context.create(user_ctx, Realtime.Workflows.TransientExecutionManager.ResourceHandler)
      branch_args = args["arguments"]
      Logger.debug("Start parallel branch #{inspect branch} #{inspect branch_args}")
      result = Machine.start(branch, ctx, branch_args)
      new_meta =
        case result do
          {:success, result} -> Map.put(meta, :success, result)
          _ -> Map.put(meta, :error, "Something went wrong")
        end
      job
      |> Ecto.Changeset.change(meta: new_meta)
      |> Realtime.Repo.update!()
      Logger.debug("Parallel finished with #{inspect result}")
      :ok
    end
  end

  def get_branch_machine(machine, state_name, branch_index) do
    state = machine.states[state_name]
    Enum.fetch(state.branches, branch_index)
  end
end
