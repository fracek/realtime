defmodule StateMachine.State.Choice do
  @moduledoc """
  Handle Choice states.
  """

  alias StateMachine.Error
  alias StateMachine.Rule

  def handle_state(state_machine, ctx, state_name, %{"Type" => "Choice"} = state, args) do
    with {:ok, choices} <- state_choices(state_name, state),
         {:ok, rules} <- collect_state_rules(state_name, choices, []) do
      case Enum.find(rules, fn rule -> rule.call(args) end) do
        nil ->
          default_next = state["Default"]
          if default_next == nil do
            error = Error.create("States.NoChoiceMatched", "State #{state_name}: no Choices matched and no Default specified")
            {:failure, error}
          else
            # TODO: handle input path
            {:continue, default_next, args}
          end
        rule ->
          # TODO: handle input path
          {:continue, rule.next, args}
      end
    else
      {:failure, error} ->
        {:failure, error}
      {:error, message} ->
        error = Error.create("Error", message)
        {:failure, error}
    end
    {:continue, args}
  end

  defp state_choices(state_name, %{"Choices" => []}),
       do: state_choices(state_name, nil)

  defp state_choices(state_name, %{"Choices" => choices}) when is_list(choices) do
    collect_state_rules(state_name, choices, [])
  end

  defp state_choices(state_name, _) do
    error = Error.create("InvalidChoices", "State #{state_name} must have non-empty Choices")
    {:error, error}
  end

  defp collect_state_rules(_state_name, [], acc), do: {:ok, acc}

  defp collect_state_rules(state_name, [choice | choices], acc) do
    with {:ok, rule} <- Rule.create(choice) do
      collect_state_rules(state_name, choices, [rule | acc])
    else
      {:error, _} ->
        error = Error.create("InvalidRule", "State #{state_name} has invalid rule")
        {:failure, error}
    end
  end
end
