defmodule StateMachine.ResourceHandler do
  @moduledoc """
  Defines a behaviour and macro for the creation of resource handler modules.
  """

  alias StateMachine.Context
  alias StateMachine.State

  @type wait ::
          {:seconds, pos_integer()}
          | {:timestamp, DateTime.t()}

  @type result ::
          {:ok, output :: State.args()}
          | {:error, reason :: String.t()}

  @callback handle_wait(State.Wait.t(), wait(), Context.user_ctx(), State.args()) :: result()
  @callback handle_task(State.Task.t(), Context.user_ctx(), State.args()) :: result()
  @callback handle_parallel(State.Parallel.t(), Context.t(), State.args()) :: result()
  @callback handle_map(State.Map.t(), Context.t(), State.args()) :: result()

  defmacro __using__(_opts) do
    quote location: :keep do
      alias StateMachine.Machine
      alias StateMachine.ResourceHandler

      @behaviour ResourceHandler

      @impl ResourceHandler
      def handle_wait(state, wait, ctx, args) do
        duration =
          case wait do
            {:seconds, seconds} when is_integer(seconds) and seconds > 0 ->
              trunc(seconds * 1000)
            {:timestamp, target} ->
              DateTime.diff(target, DateTime.utc_now(), :millisecond)
            _ ->
              {:error, "Invalid wait duration"}
          end
        Process.sleep(duration)
        {:ok, args}
      end

      @impl ResourceHandler
      def handle_parallel(state, ctx, args) do
        results =
          state.branches
          |> Enum.map(fn branch ->
            Task.async(Machine, :start, [branch, ctx, args])
          end)
          |> Enum.map(&Task.await/1)
          |> collect_task_results([])
        results
      end

      @impl ResourceHandler
      def handle_map(state, ctx, args) do
        if not is_list(args) do
          {:error, "Input must be a list"}
        else
          concurrency =
            if state.max_concurrency == 0 do System.schedulers_online() else state.max_concurrency end
          results =
            args
            |> Task.async_stream(fn arg -> Machine.start(state.iterator, ctx, arg) end, max_concurrency: concurrency, ordered: true)
            |> Enum.to_list()
            |> collect_task_results([])
          results
        end
      end

      defoverridable handle_wait: 4, handle_parallel: 3, handle_map: 3

      ## Private

      defp collect_task_results([], acc), do: {:ok, Enum.reverse(acc)}

      defp collect_task_results([task | tasks], acc) do
        case task do
          {:ok, {:success, value}} -> collect_task_results(tasks, [value | acc])
          error -> error
        end
      end
    end
  end
end
