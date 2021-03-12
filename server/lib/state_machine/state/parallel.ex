defmodule StateMachine.State.Parallel do
  @moduledoc """
  Handle Parallel states.
  """

  alias StateMachine.Catcher
  alias StateMachine.Machine
  alias StateMachine.Path
  alias StateMachine.PayloadTemplate
  alias StateMachine.ReferencePath
  alias StateMachine.Retrier
  alias StateMachine.State
  alias StateMachine.StateUtil

  use State

  @type t :: %__MODULE__{
               branches: nonempty_list(Machine.t()),
               transition: State.transition(),
               input_path: Path.t() | nil,
               output_path: Path.t() | nil,
               result_path: ReferencePath.t() | nil,
               parameters: PayloadTemplate.t() | nil,
               result_selector: PayloadTemplate.t() | nil,
               retry: list(Retrier.t()),
               catch: list(Catcher.t()),
             }

  defstruct [
    :branches,
    :transition,
    :input_path,
    :output_path,
    :result_path,
    :parameters,
    :result_selector,
    :retry,
    :catch
  ]

  @impl State
  def parse(definition) do
    with {:ok, branches} <- parse_branches(definition),
         {:ok, transition} <- StateUtil.parse_transition(definition),
         {:ok, input_path} <- StateUtil.parse_input_path(definition),
         {:ok, output_path} <- StateUtil.parse_output_path(definition),
         {:ok, result_path} <- StateUtil.parse_result_path(definition),
         {:ok, parameters} <- StateUtil.parse_parameters(definition),
         {:ok, result_selector} <- StateUtil.parse_result_selector(definition),
         {:ok, retry} <- StateUtil.parse_retry(definition),
         {:ok, catch_} <- StateUtil.parse_catch(definition) do
       state = %__MODULE__{
         branches: branches,
         transition: transition,
         input_path: input_path,
         output_path: output_path,
         result_path: result_path,
         parameters: parameters,
         result_selector: result_selector,
         catch: catch_,
       }
       {:ok, state}
    end
  end

  @impl State
  def handle(state, ctx, args) do
    handler = ctx.resource_handler
    case handler.handle_parallel(state, ctx, args) do
      {:ok, value} -> StateUtil.continue_with_result(state, value)
      {:error, error} ->
        {:error, "Parallel Retry/Catch not implemented"}
    end
  end

  @impl State
  def before_handle(state, ctx, args) do
    with {:ok, args} <- StateUtil.apply_input_path(state, args) do
      StateUtil.apply_parameters(state, ctx, args)
    end
  end

  @impl State
  def after_handle(state, ctx, args, state_args) do
    with {:ok, args} <- StateUtil.apply_result_selector(state, ctx, args),
         {:ok, args} <- StateUtil.apply_result_path(state, ctx, args, state_args) do
      StateUtil.apply_output_path(state, args)
    end
  end

  ## Private

  defp parse_branches(%{"Branches" => branches}) when is_list(branches) do
    collect_branches(branches, [])
  end

  defp parse_branches(_definition), do: {:error, "Must have non empty Branches field"}

  defp collect_branches([], acc), do: {:ok, Enum.reverse(acc)}

  defp collect_branches([branch | branches], acc) do
    with {:ok, branch} <- Machine.parse(branch) do
      collect_branches(branches, [branch | acc])
    end
  end
end
