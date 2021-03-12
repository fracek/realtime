defmodule StateMachine.Machine do
  alias StateMachine.Context
  alias StateMachine.State

  @type t :: %__MODULE__{
               start_at: State.state_name(),
               states: %{State.state_name() => State.t()}
             }

  @type result ::
          {:success, output :: State.args()}
          | {:failure, error :: Error.t()}
          | {:error, reason :: term()}

  defstruct [:start_at, :states]

  @spec parse(map()) :: {:ok, t()} | {:error, reason :: String.t()}
  def parse(definition), do: do_parse(definition)

  @spec start(t(), Context.t(), State.args()) :: result()
  def start(state_machine, ctx, args) do
    execute_state(state_machine, state_machine.start_at, ctx, args)
  end

  def handle_state(state_machine, state_name, ctx, args) when is_binary(state_name) do
    state = state_machine.states[state_name]
    State.handle_state(state, ctx, args)
  end

  ## Private

  defp execute_state(state_machine, state_name, ctx, args) do
    case handle_state(state_machine, state_name, ctx, args) do
      {:continue, next_state_name, result} ->
        execute_state(state_machine, next_state_name, ctx, result)
      {:success, result} ->
        {:success, result}
      failure -> failure
    end
  end

  defp do_parse(%{"StartAt" => start_at, "States" => states}) do
    with {:ok, states} = parse_states(Map.to_list(states), []) do
      machine = %__MODULE__{
        start_at: start_at,
        states: states
      }
      {:ok, machine}
    end
  end

  defp do_parse(_definition), do: {:error, "Definition requires StartAt and States fields"}

  defp parse_states([], acc), do: {:ok, Enum.into(acc, %{})}

  defp parse_states([{state_name, state_def} | states], acc) do
    with {:ok, state} = State.parse(state_def) do
      parse_states(states, [{state_name, state} | acc])
    end
  end
end
