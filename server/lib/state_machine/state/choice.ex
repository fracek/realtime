defmodule StateMachine.State.Choice do
  @moduledoc """
  Handle Choice states.
  """

  alias StateMachine.Error
  alias StateMachine.Path
  alias StateMachine.PayloadTemplate
  alias StateMachine.ReferencePath
  alias StateMachine.Rule
  alias StateMachine.State
  alias StateMachine.StateUtil

  use State

  defstruct [:name, :default, :choices, :input_path, :output_path]

  @type t :: %__MODULE__{
               name: State.state_name(),
               default: State.state_name() | nil,
               choices: nonempty_list(Rule.t()),
               input_path: Path.t() | nil,
               output_path: Path.t() | nil,
             }

  @impl State
  def parse(state_name, definition) do
    with {:ok, default} <- parse_default(definition),
         {:ok, choices} <- parse_choices(definition),
         {:ok, input_path} <- StateUtil.parse_input_path(definition),
         {:ok, output_path} <- StateUtil.parse_output_path(definition) do
      state = %__MODULE__{
        name: state_name,
        default: default,
        choices: choices,
        input_path: input_path,
        output_path: output_path
      }
      {:ok, state}
    end
  end

  @impl State
  def handle(state, _ctx, args) do
    case Enum.find(state.choices, fn rule -> Rule.call(rule, args) end) do
      nil ->
        default_next = state.default
        if default_next == nil do
          error = Error.create("States.NoChoiceMatched", "No Choices matched and no Default specified")
          {:failure, error}
        else
          {:continue, default_next, args}
        end
      rule ->
        {:continue, rule.next, args}
    end
  end

  @impl State
  def before_handle(state, _ctx, args) do
    StateUtil.apply_input_path(state, args)
  end

  @impl State
  def after_handle(state, _ctx, args, _state_args) do
    StateUtil.apply_output_path(state, args)
  end

  ## Private

  defp parse_default(definition) do
    default = Map.get(definition, "Default")
    {:ok, default}
  end

  defp parse_choices(definition) do
    with {:ok, choices} <- state_choices(definition) do
      collect_state_rules(choices, [])
    end
  end

  defp state_choices(%{"Choices" => []}),
       do: state_choices(nil)

  defp state_choices(%{"Choices" => choices}) when is_list(choices) do
    {:ok, choices}
  end

  defp state_choices(_) do
    error = Error.create("InvalidChoices", "State must have non-empty Choices")
    {:error, error}
  end

  defp collect_state_rules([], acc), do: {:ok, acc}

  defp collect_state_rules([choice | choices], acc) do
    with {:ok, rule} <- Rule.create(choice) do
      collect_state_rules(choices, [rule | acc])
    else
      {:error, err} ->
        error = Error.create("InvalidRule", "State has invalid rule")
        {:failure, error}
    end
  end
end
