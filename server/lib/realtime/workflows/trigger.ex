defmodule Realtime.Workflows.Trigger do
  require Logger

  alias Realtime.Workflows.Manager
  alias Realtime.Workflows

  def notify(txn) do
    workflows = Manager.workflows_for_change(txn)

    # TODO: convert to map in a proper way
    txn_as_map = Jason.decode!(Jason.encode!(txn))

    args = %{
      arguments: txn_as_map,
      is_persistent: true,
      has_logs: false,
    }

    Logger.debug("Trigger: #{inspect workflows}")

    Enum.each(workflows, fn workflow ->
      Workflows.invoke_workflow(workflow, args)
    end)
  end
end
