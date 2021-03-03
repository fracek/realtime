defmodule StateMachine.State.Fail do
  @moduledoc """
  Handle Fail states.
  """

  alias StateMachine.Error

  def handle_state(_state_machine, _ctx, _state_name, %{"Type" => "Fail"} = state, _args) do
    error = state["Error"]
    cause = state["Cause"]
    error = Error.create(error, cause)
    {:failure, error}
  end
end
