defmodule StateMachine.State do
  @moduledoc """
  Handle a state machine state.
  """

  def continue_with_result(state, result) do
    case state["End"] do
      true -> {:success, result}
      _ ->
        case state["Next"] do
          nil -> {:error, "State must have one of End or Next"}
          next -> {:continue, next, result}
        end
    end
  end
end
