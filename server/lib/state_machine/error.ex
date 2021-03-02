defmodule StateMachine.Error do
  @moduledoc """
  Represent an execution error. Errors have a name and a human-readable cause.
  """

  defstruct [:name, :cause]

  @doc """
  Create a new error.
  """
  def create(name, cause) do
    %__MODULE__{
      name: name,
      cause: cause
    }
  end
end
