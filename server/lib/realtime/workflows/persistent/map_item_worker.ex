defmodule Realtime.Workflows.Persistent.MapItemWorker do
  @moduledoc false

  alias Realtime.Workflows.Context
  alias Realtime.Workflows.Persistent.ResourceHandler
  alias Realtime.Workflows
  alias StateMachine.Interpreter
  alias StateMachine.Machine
  alias StateMachine.State

  require Logger

  use Oban.Worker, queue: :workflow_interpreter

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, meta: meta} = job) do
    Logger.debug("Resume map #{inspect args}")
    with {:ok, execution} <- Workflows.get_workflow_execution(args["execution_id"]),
         {:ok, workflow} <- Workflows.get_workflow(args["workflow_id"]),
         {:ok, machine} <- Machine.parse(workflow.definition),
         {:ok, state} <- get_state_at_path(machine, args["state_path"]) do
      Logger.debug("At pah #{inspect state}")
      user_ctx = Context.create(workflow, execution, args["state_path"])
      ctx = StateMachine.Context.create(user_ctx, Realtime.Workflows.Persistent.ResourceHandler)
      iterator_args = args["arg"]
      Logger.debug("Start map item #{inspect state.iterator} #{inspect iterator_args}")
      result = Machine.start(state.iterator, ctx, iterator_args)
      Logger.debug("Map result #{inspect result}")
    end
  end

  def get_state_at_path(machine, [p | path]) when is_binary(p) do
    {:ok, machine.states[p]}
  end

  def get_state_at_path(_machine, path) do
    {:error, "invalid path #{inspect path}"}
  end

end
