defmodule StateMachine.State.Fail do
  @moduledoc """
  Handle Fail states.
  """

  alias StateMachine.Error
  alias StateMachine.Path
  alias StateMachine.State

  use State

  @type t :: %__MODULE__{
               error: String.t(),
               cause: String.t(),
             }

  defstruct [:error, :cause]

  @impl State
  def parse(definition) do
    with {:ok, error} <- parse_error(definition),
         {:ok, cause} <- parse_cause(definition) do
      state = %__MODULE__{
        error: error,
        cause: cause,
      }
      {:ok, state}
    end
  end

  @impl State
  def handle(state, _ctx, _args) do
    error = Error.create(state.error, state.cause)
    {:failure, error}
  end

  ## Private

  defp parse_error(%{"Error" => error}), do: {:ok, error}
  defp parse_error(_definition), do: {:error, "Must have field Error"}

  defp parse_cause(%{"Cause" => cause}), do: {:ok, cause}
  defp parse_cause(_definition), do: {:error, "Must have field Cause"}

end
