defmodule Realtime.Workflows.Persistent.ResumeTaskWorker do
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
    Logger.info("Resume task/wait #{inspect args}")
    with {:ok, execution} <- Workflows.get_workflow_execution(args["execution_id"]),
         {:ok, workflow} <- Workflows.get_workflow(args["workflow_id"]),
         {:ok, machine} <- Machine.parse(workflow.definition),
         {:ok, state} <- get_state_at_path(machine, args["state_path"]) do
      ctx = Context.create(workflow, execution, args["state_path"])
      state_args = execution.arguments # TODO: user real state arguments
      result = args["result"]
      {state, machine} =
        if state.name == "EmailUsers" do
          {state.iterator.states[args["state_name"]], state.iterator}
        else
          {state, machine}
        end

      Logger.debug("Resume at state #{inspect state}")
      result = Interpreter.resume_execution(ctx, ResourceHandler, machine, state, state_args, result)
      Logger.debug("Resume finished with #{inspect result}")
      job_id = args["job_id"]
      Logger.debug("Part of job, continue #{inspect job_id}")
      :ok
    end
  end

  def get_state_at_path(machine, [p | path]) when is_binary(p) do
    {:ok, machine.states[p]}
  end

  def get_state_at_path(_machine, path) do
    {:error, "invalid path #{inspect path}"}
  end

end
