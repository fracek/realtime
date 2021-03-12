defmodule StateMachine.StateHandler do
  @moduledoc false

  # This module is needed just to break a deadlock between State and State.*

  alias StateMachine.State

  def handle_state(%State.Pass{} = state, ctx, args),
      do: State.Pass.handle_state(state, ctx, args)

  def handle_state(%State.Task{} = state, ctx, args),
      do: State.Task.handle_state(state, ctx, args)

  def handle_state(%State.Wait{} = state, ctx, args),
      do: State.Wait.handle_state(state, ctx, args)

  def handle_state(%State.Choice{} = state, ctx, args),
      do: State.Choice.handle_state(state, ctx, args)

  def handle_state(%State.Succeed{} = state, ctx, args),
      do: State.Succeed.handle_state(state, ctx, args)

  def handle_state(%State.Fail{} = state, ctx, args),
      do: State.Fail.handle_state(state, ctx, args)

  def handle_state(%State.Parallel{} = state, ctx, args),
      do: State.Parallel.handle_state(state, ctx, args)

  def handle_state(%State.Map{} = state, ctx, args),
      do: State.Map.handle_state(state, ctx, args)

  def handle_state(state, _ctx, _args) do
    {:error, "handle_state: unhandled state"}
  end
end
