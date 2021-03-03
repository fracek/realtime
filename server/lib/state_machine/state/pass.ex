defmodule StateMachine.State.Pass do
  @moduledoc """
  Handle Pass states.
  """

  alias StateMachine.State

  def handle_state(_state_machine, _ctx, _state_name, %{"Type" => "Pass"} = state, args) do
    # TODO: transform input to output
    State.continue_with_result(state, args)
  end
end
