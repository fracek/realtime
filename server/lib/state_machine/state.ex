defmodule StateMachine.State do
  @moduledoc """
  Handle a state machine state.
  """

  alias StateMachine.Context
  alias StateMachine.Error
  alias StateMachine.PayloadTemplate
  alias StateMachine.State
  alias StateMachine.StateHandler

  @type args :: any()
  @type state_name :: String.t()
  @type transition :: {:next, state_name()} | :end

  @type state ::
          State.Choice.t()
          | State.Task.t()
          | State.Choice.t()
          | State.Wait.t()
          | State.Succeed.t()
          | State.Fail.t()
          | State.Parallel.t()
          | State.Map.t()

  @type result ::
          {:success, output :: args()}
          | {:yield, output :: args()}
          | {:continue, next :: state_name(), output :: args()}
          | {:failure, error :: Error.t()}
          | {:error, reason :: term()}

  @callback parse(state_name(), map()) :: {:ok, state()} | {:error, term()}
  @callback before_handle(state(), Context.t(), args()) :: {:ok, term()} | {:error, term()}
  @callback handle_state(state(), Context.t(), args()) :: result()
  @callback handle(state(), Context.t(), args()) :: result()
  @callback resume(state(), Context.t(), args(), args()) :: result()
  @callback after_handle(state(), Context.t(), args(), args()) :: {:ok, term()} | {:error, term()}

  @spec parse(state_name(), map()) :: {:ok, state()} | {:error, term()}
  def parse(state_name, state), do: do_parse(state_name, state)

  @spec handle_state(state(), Context.t(), args()) :: result()
  def handle_state(state, ctx, args), do: StateHandler.handle_state(state, ctx, args)

  def resume(state, ctx, state_args, result), do: StateHandler.resume(state, ctx, state_args, result)

  defmacro __using__(_opts) do
    quote location: :keep do
      alias StateMachine.State
      alias StateMachine.StateUtil

      @behaviour State

      @impl State
      def before_handle(_state, _ctx, args) do
        {:ok, args}
      end

      @impl State
      def after_handle(_state, _ctx, args, _state_args) do
        {:ok, args}
      end

      @impl State
      def handle_state(state, ctx, args) do
        state_args = args
        with {:ok, args} <- before_handle(state, ctx, args) do
          case handle(state, ctx, args) do
            {:success, output} ->
              with {:ok, output} <- after_handle(state, ctx, output, state_args) do
                {:success, output}
              end
            {:continue, next, output} ->
              with {:ok, output} <- after_handle(state, ctx, output, state_args) do
                {:continue, next, output}
              end
            {:yield, output} ->
              with {:ok, output} <- after_handle(state, ctx, output, state_args) do
                {:yield, output}
              end
            error ->
              error
          end
        end
      end

      @impl State
      def resume(state, ctx, state_args, result) do
        case StateUtil.continue_with_result(state, result) do
            {:success, output} ->
              with {:ok, output} <- after_handle(state, ctx, output, state_args) do
                {:success, output}
              end
            {:continue, next, output} ->
              with {:ok, output} <- after_handle(state, ctx, output, state_args) do
                {:continue, next, output}
              end
            error ->
              error
        end
      end

      defoverridable before_handle: 3, after_handle: 4, handle_state: 3, resume: 4
    end
  end

  ## Private

  defp do_parse(state_name, %{"Type" => "Pass"} = state),
      do: State.Pass.parse(state_name, state)

  defp do_parse(state_name, %{"Type" => "Task"} = state),
      do: State.Task.parse(state_name, state)

  defp do_parse(state_name, %{"Type" => "Choice"} = state),
      do: State.Choice.parse(state_name, state)

  defp do_parse(state_name, %{"Type" => "Wait"} = state),
      do: State.Wait.parse(state_name, state)

  defp do_parse(state_name, %{"Type" => "Succeed"} = state),
      do: State.Succeed.parse(state_name, state)

  defp do_parse(state_name, %{"Type" => "Fail"} = state),
      do: State.Fail.parse(state_name, state)

  defp do_parse(state_name, %{"Type" => "Parallel"} = state),
      do: State.Parallel.parse(state_name, state)

  defp do_parse(state_name, %{"Type" => "Map"} = state),
      do: State.Map.parse(state_name, state)

  defp do_parse(state_name, state) do
    {:error, "parse: unhandled state #{state_name} #{inspect state["Type"]}"}
  end
end
