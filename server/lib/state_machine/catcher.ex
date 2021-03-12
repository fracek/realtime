defmodule StateMachine.Catcher do
  @moduledoc false

  @opaque t :: module()

  def create(_attrs) do
    {:error, "Catcher.create not implemented"}
  end
end
