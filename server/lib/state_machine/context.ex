defmodule StateMachine.Context do
  defstruct [:workflow, :execution, :resources, :reply_to]

  def create(workflow, execution, opts \\ []) do
    config = interpreter_configuration()
    resources = Keyword.get(config, :resources)
    reply_to = Keyword.get(opts, :reply_to)

    %__MODULE__{
      workflow: workflow,
      execution: execution,
      resources: resources,
      reply_to: reply_to
    }
  end

  defp interpreter_configuration() do
    Application.fetch_env!(:realtime, StateMachine)
  end
end
