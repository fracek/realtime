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

  def handle_state(nil, _ctx, _args) do
    {:error, "handle_state: unhandled state nil"}
  end

  def handle_state(_state, _ctx, _args) do
    {:error, "handle_state: unhandled state"}
  end

  def resume(%State.Pass{} = state, ctx, state_args, result),
      do: State.Pass.resume(state, ctx, state_args, result)

  def resume(%State.Task{} = state, ctx, state_args, result),
      do: State.Task.resume(state, ctx, state_args, result)

  def resume(%State.Wait{} = state, ctx, state_args, result),
      do: State.Wait.resume(state, ctx, state_args, result)

  def resume(%State.Choice{} = state, ctx, state_args, result),
      do: State.Choice.resume(state, ctx, state_args, result)

  def resume(%State.Succeed{} = state, ctx, state_args, result),
      do: State.Succeed.resume(state, ctx, state_args, result)

  def resume(%State.Fail{} = state, ctx, state_args, result),
      do: State.Fail.resume(state, ctx, state_args, result)

  def resume(%State.Parallel{} = state, ctx, state_args, result),
      do: State.Parallel.resume(state, ctx, state_args, result)

  def resume(%State.Map{} = state, ctx, state_args, result),
      do: State.Map.resume(state, ctx, state_args, result)

  def resume(nil, _ctx, _args, _result) do
    {:error, "resume: state is nil"}
  end

  def resume(_state, _ctx, _args, _result) do
    {:error, "resume: unhandled state"}
  end

end
