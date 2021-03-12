defmodule StateMachine.State.Map do
  @moduledoc """
  Handle Map states.
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
               iterator: Machine.t(),
               items_path: ReferencePath.t() | nil,
               max_concurrency: non_neg_integer(),
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
    :iterator,
    :items_path,
    :max_concurrency,
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
    with {:ok, iterator} <- parse_iterator(definition),
         {:ok, items_path} <- parse_items_path(definition),
         {:ok, max_concurrency} <- parse_max_concurrency(definition),
         {:ok, transition} <- StateUtil.parse_transition(definition),
         {:ok, input_path} <- StateUtil.parse_input_path(definition),
         {:ok, output_path} <- StateUtil.parse_output_path(definition),
         {:ok, result_path} <- StateUtil.parse_result_path(definition),
         {:ok, parameters} <- StateUtil.parse_parameters(definition),
         {:ok, result_selector} <- StateUtil.parse_result_selector(definition),
         {:ok, retry} <- StateUtil.parse_retry(definition),
         {:ok, catch_} <- StateUtil.parse_catch(definition) do
       state = %__MODULE__{
         iterator: iterator,
         items_path: items_path,
         max_concurrency: max_concurrency,
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
    case handler.handle_map(state, ctx, args) do
      {:ok, value} -> StateUtil.continue_with_result(state, value)
      {:error, error} ->
        {:error, "Map Retry/Catch not implemented"}
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

  defp parse_iterator(%{"Iterator" => iterator}) do
    Machine.parse(iterator)
  end

  defp parse_iterator(_definition), do: {:error, "Must have Iterator field"}

  defp parse_items_path(%{"ItemsPath" => path}) do
    ReferencePath.create(path)
  end

  defp parse_items_path(_definition) do
    # The default value of "ItemsPath" is "$", which is to say the whole effective input.
    ReferencePath.create("$")
  end

  defp parse_max_concurrency(%{"MaxConcurrency" => concurrency}) do
    if is_integer(concurrency) and concurrency >= 0 do
      {:ok, concurrency}
    else
      {:error, "MaxConcurrency must be a non-negative integer"}
    end
  end

  defp parse_max_concurrency(_definition), do: {:ok, 0}
end
