defmodule StateMachine.State.Succeed do
  @moduledoc """
  Handle Succeed states.
  """

  alias StateMachine.Path
  alias StateMachine.State
  alias StateMachine.StateUtil

  use State

  @type t :: %__MODULE__{
               name: State.state_name(),
               input_path: Path.t() | nil,
               output_path: Path.t() | nil,
             }

  defstruct [:name, :input_path, :output_path]

  @impl State
  def parse(state_name, definition) do
    with {:ok, input_path} <- StateUtil.parse_input_path(definition),
         {:ok, output_path} <- StateUtil.parse_output_path(definition) do
      state = %__MODULE__{
        name: state_name,
        input_path: input_path,
        output_path: output_path
      }
      {:ok, state}
    end
  end

  @impl State
  def handle(_state, _ctx, args) do
    {:success, args}
  end

  @impl State
  def before_handle(state, _ctx, args) do
    StateUtil.apply_input_path(state, args)
  end

  @impl State
  def after_handle(state, _ctx, args, _state_args) do
    StateUtil.apply_output_path(state, args)
  end
end
