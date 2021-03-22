defmodule StateMachine.State.Pass do
  @moduledoc """
  Handle Pass states.
  """

  alias StateMachine.Path
  alias StateMachine.PayloadTemplate
  alias StateMachine.ReferencePath
  alias StateMachine.State
  alias StateMachine.StateUtil

  use State

  @type t :: %__MODULE__{
               name: State.state_name(),
               result: State.args(),
               transition: State.transition(),
               input_path: Path.t() | nil,
               output_path: Path.t() | nil,
               result_path: ReferencePath.t() | nil,
               parameters: PayloadTemplate.t() | nil
             }

  defstruct [:name, :result, :transition, :input_path, :output_path, :result_path, :parameters]

  @impl State
  def parse(state_name, definition) do
    result = parse_result(definition)
    with {:ok, transition} <- StateUtil.parse_transition(definition),
         {:ok, input_path} <- StateUtil.parse_input_path(definition),
         {:ok, output_path} <- StateUtil.parse_output_path(definition),
         {:ok, result_path} <- StateUtil.parse_result_path(definition),
         {:ok, parameters} <- StateUtil.parse_parameters(definition) do
       state = %__MODULE__{
         name: state_name,
         result: result,
         transition: transition,
         input_path: input_path,
         output_path: output_path,
         result_path: result_path,
         parameters: parameters
       }
       {:ok, state}
    end
  end

  @impl State
  def handle(state, _ctx, args) do
    StateUtil.continue_with_result(state, args)
  end

  @impl State
  def before_handle(state, ctx, args) do
    with {:ok, args} <- StateUtil.apply_input_path(state, args) do
      StateUtil.apply_parameters(state, ctx, args)
    end
  end

  @impl State
  def after_handle(state, ctx, args, state_args) do
    with {:ok, args} <- StateUtil.apply_result_path(state, ctx, args, state_args) do
      StateUtil.apply_output_path(state, args)
    end
  end

  defp parse_result(definition) do
    Map.get(definition, "Result", nil)
  end
end
