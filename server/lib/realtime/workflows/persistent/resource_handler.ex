defmodule Realtime.Workflows.Persistent.ResourceHandler do
  @moduledoc false

  alias Realtime.Workflows.Persistent.ResumeTaskWorker
  alias Realtime.Workflows.Persistent.ParallelBranchWorker
  alias Realtime.Workflows.Persistent.MapItemWorker
  alias StateMachine.ResourceHandler

  require Logger

  use ResourceHandler

  @impl ResourceHandler
  def handle_task(state, ctx, args) do
    # TODO: make http call or whatever
    call_result = args

    resume_args = %{
      workflow_id: ctx.workflow.id,
      execution_id: ctx.execution.id,
      state_path: ctx.state_path,
      result: call_result,
      state_name: state.name,
    }

    ResumeTaskWorker.new(resume_args)
    |> Oban.insert!()

    {:yield, args}
  end

  @impl ResourceHandler
  def handle_wait(state, wait, ctx, args) do
    resume_args = %{
      workflow_id: ctx.workflow.id,
      execution_id: ctx.execution.id,
      state_path: ctx.state_path,
      result: args,
      state_name: state.name,
    }

    case wait do
      {:seconds, seconds} when is_integer(seconds) and seconds > 0 ->
        ResumeTaskWorker.new(resume_args, schedule_in: seconds)
        |> Oban.insert!()
        {:yield, args}
      {:timestamp, target} ->
        ResumeTaskWorker.new(resume_args, schedule_at: target)
        |> Oban.insert!()
        {:yield, args}
      _ ->
        {:error, "Invalid wait duration"}
    end
  end

  @impl ResourceHandler
  def handle_parallel(state, ctx, args) do
    branch_args = %{
      workflow_id: ctx.user_ctx.workflow.id,
      execution_id: ctx.user_ctx.execution.id,
      state_path: ctx.user_ctx.state_path ++ [state.name],
      arguments: args,
      state_name: state.name,
    }

    job_id = Ecto.UUID.generate()

    state.branches
    |> Enum.with_index()
    |> Enum.map(
         fn {branch, index} ->
           ParallelBranchWorker.new(
             Map.put(%{branch_args | state_path: branch_args.state_path ++ [index]}, :branch_index, index),
             meta: %{
               job_id: job_id
             }
           )
           |> Oban.insert!()
         end
       )

    {:yield, args}
  end

  @impl ResourceHandler
  def handle_map(state, ctx, args) do
    if not is_list(args) do
      {:error, "Input must be a list"}
    else
      branch_args = %{
        workflow_id: ctx.user_ctx.workflow.id,
        execution_id: ctx.user_ctx.execution.id,
        state_path: ctx.user_ctx.state_path ++ [state.name],
        state_name: state.name,
      }

      job_id = Ecto.UUID.generate()

      args
      |> Enum.with_index()
      |> Enum.map(
           fn {arg, index} ->
             MapItemWorker.new(
               Map.put(%{branch_args | state_path: branch_args.state_path}, :arg, arg),
               meta: %{
                 job_id: job_id
               }
             )
             |> Oban.insert!()
           end
         )
      {:yield, args}
    end
  end
end
