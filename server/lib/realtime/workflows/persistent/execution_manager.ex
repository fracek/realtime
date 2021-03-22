defmodule Realtime.Workflows.Persistent.ExecutionManager do
  @moduledoc false

  alias Realtime.Workflows.Persistent.InterpreterWorker

  require Logger

  def start_workflow_execution(workflow, execution, opts \\ []) do
    args = %{
      arguments: execution.arguments,
      workflow_id: workflow.id,
      execution_id: execution.id,
      state_path: [],
    }

    Logger.debug("Start persistent workflow #{inspect args}")

    InterpreterWorker.new(args)
    |> Oban.insert!()
  end
end
