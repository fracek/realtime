defmodule StateMachine.State.Task do
  @moduledoc """
  Handle Task states.
  """

  alias StateMachine.Catcher
  alias StateMachine.Path
  alias StateMachine.PayloadTemplate
  alias StateMachine.ReferencePath
  alias StateMachine.Retrier
  alias StateMachine.State
  alias StateMachine.StateUtil

  use State

  @type t :: %__MODULE__{
               resource: String.t(),
               timeout: {:value, pos_integer()} | {:reference, ReferencePath.t()} | nil,
               heartbeat: {:value, pos_integer()} | {:reference, ReferencePath.t()} | nil,
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
    :resource,
    :timeout,
    :heartbeat,
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
    with {:ok, resource} <- parse_resource(definition),
         {:ok, timeout} <- parse_timeout(definition),
         {:ok, heartbeat} <- parse_heartbeat(definition),
         {:ok, transition} <- StateUtil.parse_transition(definition),
         {:ok, input_path} <- StateUtil.parse_input_path(definition),
         {:ok, output_path} <- StateUtil.parse_output_path(definition),
         {:ok, result_path} <- StateUtil.parse_result_path(definition),
         {:ok, parameters} <- StateUtil.parse_parameters(definition),
         {:ok, result_selector} <- StateUtil.parse_result_selector(definition),
         {:ok, retry} <- StateUtil.parse_retry(definition),
         {:ok, catch_} <- StateUtil.parse_catch(definition) do
       state = %__MODULE__{
         resource: resource,
         timeout: timeout,
         heartbeat: heartbeat,
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
    case handler.handle_task(state, ctx.user_ctx, args) do
      {:ok, value} -> StateUtil.continue_with_result(state, value)
      {:error, error} ->
        {:error, "Task Retry/Catch not implemented"}
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

  defp parse_resource(%{"Resource" => resource}) do
    if resource == nil do
      {:error, "Resource must be non-null"}
    else
      {:ok, resource}
    end
  end

  defp parse_resource(_definition), do: {:error, "Must have Resource"}

  defp parse_timeout(%{"TimeoutSeconds" => _, "TimeoutSecondsPath" => _}) do
    {:error, "Must have only one of TimeoutSeconds or TimeoutSecondsPath"}
  end

  defp parse_timeout(%{"TimeoutSeconds" => seconds}) do
    if is_integer(seconds) and seconds > 0 do
      {:ok, {:value, seconds}}
    else
      {:error, "TimeoutSeconds must be positive integer"}
    end
  end

  defp parse_timeout(%{"TimeoutSecondsPath" => path}) do
    with {:ok, path} <- ReferencePath.create(path) do
      {:ok, {:reference, path}}
    end
  end

  defp parse_timeout(_definition), do: {:ok, nil}

  defp parse_heartbeat(%{"HeartbeatSeconds" => _, "HeartbeatSecondsPath" => _}) do
    {:error, "Must have only one of HeartbeatSeconds or HeartbeatSecondsPath"}
  end

  defp parse_heartbeat(%{"HeartbeatSeconds" => seconds}) do
    if is_integer(seconds) and seconds > 0 do
      {:ok, {:value, seconds}}
    else
      {:error, "HeartbeatSeconds must be positive integer"}
    end
  end

  defp parse_heartbeat(%{"HeartbeatSecondsPath" => path}) do
    with {:ok, path} <- ReferencePath.create(path) do
      {:ok, {:reference, path}}
    end
  end

  defp parse_heartbeat(_definition), do: {:ok, nil}
end
