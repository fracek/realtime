defmodule Realtime.Workflows.Transient.ResourceHandler do
  @moduledoc false

  alias StateMachine.ResourceHandler

  use ResourceHandler

  require Logger

  @impl ResourceHandler
  def handle_task(_state, _ctx, args) do
    Logger.info("Task #{inspect args}")
    {:ok, args}
  end
end
