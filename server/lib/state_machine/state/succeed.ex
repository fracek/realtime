defmodule StateMachine.State.Succeed do
  @moduledoc """
  Handle Succeed states.
  """

  def handle_state(_state_machine, _ctx, _state_name, %{"Type" => "Succeed"}, args) do
    {:success, args}
  end
end
