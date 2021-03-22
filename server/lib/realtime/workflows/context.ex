defmodule Realtime.Workflows.Context do
  @moduledoc false

  defstruct [:workflow, :execution, :resources, :state_path, :reply_to]

  def create(workflow, execution, state_path, opts \\ []) do
    config = interpreter_configuration()
    resources = Keyword.get(config, :resources)
    reply_to = Keyword.get(opts, :reply_to)

    %__MODULE__{
      workflow: workflow,
      execution: execution,
      state_path: state_path,
      resources: resources,
      reply_to: reply_to
    }
  end

  defp interpreter_configuration() do
    Application.fetch_env!(:realtime, StateMachine)
  end

end
