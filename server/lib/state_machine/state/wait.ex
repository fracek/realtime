defmodule StateMachine.State.Wait do
  @moduledoc """
  Handle Wait states.
  """

  alias StateMachine.Path
  alias StateMachine.ReferencePath
  alias StateMachine.State
  alias StateMachine.StateUtil

  use State

  @type wait ::
          {:seconds, pos_integer()}
          | {:seconds_path, Path.t()}
          | {:timestamp, DateTime.t()}
          | {:timestamp_path, Path.t()}

  @type t :: %__MODULE__{
               name: State.state_name(),
               wait: wait(),
               transition: State.transition(),
               input_path: Path.t() | nil,
               output_path: Path.t() | nil,
             }

  @seconds "Seconds"
  @seconds_path "SecondsPath"
  @timestamp "Timestamp"
  @timestamp_path "TimestampPath"

  @required_keys_error "Must have at most one of Seconds, SecondsPath, Timestamp, TimestampPath"

  defstruct [:name, :wait, :transition, :input_path, :output_path]

  @impl State
  def parse(state_name, definition) do
    with {:ok, wait} <- parse_wait(definition),
         {:ok, transition} <- StateUtil.parse_transition(definition),
         {:ok, input_path} <- StateUtil.parse_input_path(definition),
         {:ok, output_path} <- StateUtil.parse_output_path(definition) do
      state = %__MODULE__{
        name: state_name,
        wait: wait,
        transition: transition,
        input_path: input_path,
        output_path: output_path
      }
      {:ok, state}
    end
  end

  @impl State
  def handle(state, ctx, args) do
    handler = ctx.resource_handler
    with {:ok, wait} <- resolve_wait(state.wait, args) do
      case handler.handle_wait(state, wait, ctx.user_ctx, args) do
        {:ok, value} -> StateUtil.continue_with_result(state, value)
        {:yield, value} -> StateUtil.yield_result(state, value)
        {:error, error} ->
          {:error, "Wait Retry/Catch not implemented"}
      end
    end
  end

  @impl State
  def before_handle(state, ctx, args) do
    StateUtil.apply_input_path(state, args)
  end

  @impl State
  def after_handle(state, ctx, args, state_args) do
    StateUtil.apply_output_path(state, args)
  end

  ## Private

  defp parse_wait(%{"Seconds" => seconds} = state) do
    with :ok <- validate_no_extra_keys(state, [@seconds_path, @timestamp, @timestamp_path]) do
      if is_integer(seconds) and seconds > 0 do
        {:ok, {:seconds, seconds}}
      else
        {:error, "Seconds must be a positive integer"}
      end
    end
  end

  defp parse_wait(%{"SecondsPath" => seconds_path} = state) do
    with :ok <- validate_no_extra_keys(state, [@seconds, @timestamp, @timestamp_path]),
         {:ok, seconds} <- ReferencePath.create(seconds_path) do
      {:ok, {:seconds_path, seconds}}
    end
  end

  defp parse_wait(%{"Timestamp" => timestamp} = state) do
    with :ok <- validate_no_extra_keys(state, [@seconds, @seconds_path, @timestamp_path]),
         {:ok, timestamp} <- DateTime.from_iso8601(timestamp) do
      {:ok, {:timestamp, timestamp}}
    end
  end

  defp parse_wait(%{"TimestampPath" => timestamp_path} = state) do
    with :ok <- validate_no_extra_keys(state, [@seconds, @seconds_path, @timestamp]),
         {:ok, timestamp} <- ReferencePath.create(timestamp_path) do
      {:ok, {:timestamp_path, timestamp}}
    end
  end

  defp parse_wait(_state, _args) do
    {:error, @required_keys_error}
  end

  defp validate_no_extra_keys(state, other_keys) do
    if state_has_keys(state, other_keys) do
      {:error, @required_keys_error}
    end
    :ok
  end

  defp state_has_keys(state, keys) do
    Enum.any?(keys, fn key -> Map.has_key?(state, key) end)
  end

  defp resolve_wait({:seconds_path, path}, args) do
    with {:ok, seconds} <- ReferencePath.query(path, args) do
      {:ok, {:seconds, seconds}}
    end
  end

  defp resolve_wait({:timestamp_path, path}, args) do
    with {:ok, timestamp} <- ReferencePath.query(path, args) do
      {:ok, {:timestamp, timestamp}}
    end
  end

  defp resolve_wait(wait, _args), do: {:ok, wait}
end
