defmodule Realtime.Workflows.Workflow do
  @moduledoc """
  Workflows represent a series of steps taken in response to an event.

  Workflows are defined using [Amazon States Language](https://states-language.net/), refer to the spec to understand
  the different types of states available.

  ## Fields

   * `id`: the unique id of the workflow.
   * `name`: the human-readable name of the workflow.
   * `definition`: the JSON defining the Amazon States Language state machine.
   * `default_execution_type`: the execution type used when the workflow is started in response to a realtime event.
     Users can override the execution type when starting the workflow manually (for example, to debug it).
   * `default_log_type`: the log type used when the workflow is started in response to a realtime event. Users can
     override the execution log type when starting the workflow manually.
   * `executions`: a list of executions of this workflow.
  """
  use Ecto.Schema
  alias Ecto.Changeset
  alias StateMachine.Interpreter
  alias Realtime.TransactionFilter

  @schema_prefix Application.get_env(:realtime, :workflows_db_schema)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  @required_fields ~w(name trigger definition default_execution_type default_log_type)a

  schema "workflows" do
    field :name, :string
    field :trigger, :string
    field :definition, :map
    field :default_execution_type, Ecto.Enum, values: [:persistent, :transient]
    field :default_log_type, Ecto.Enum, values: [:none, :postgres]

    timestamps()

    has_many :executions, Realtime.Workflows.Execution
  end

  @doc false
  def changeset(workflow, params \\ %{}) do
    workflow
    |> Changeset.cast(params, @required_fields)
    |> Changeset.validate_required(@required_fields)
    |> Changeset.validate_length(:name, min: 5)
    |> Changeset.unique_constraint(:name)
    |> Changeset.validate_change(:definition, &validate_state_machine/2)
    |> Changeset.validate_change(:trigger, &validate_trigger/2)
  end

  @doc """
  Returns a transaction filter that matches this table.
  """
  def transaction_filter do
    "#{%__MODULE__{}.__meta__.prefix}:#{%__MODULE__{}.__meta__.source}"
  end

  @doc """
  Returns the table name.
  """
  def table_name do
    %__MODULE__{}.__meta__.source
  end

  @doc """
  Returns the table schema.
  """
  def table_schema do
    %__MODULE__{}.__meta__.prefix
  end

  defp validate_state_machine(field, definition) do
    if Interpreter.state_machine_valid?(definition) do
      []
    else
      [{field, "is invalid"}]
    end
  end

  defp validate_trigger(field, trigger) do
    case TransactionFilter.parse_relation_filter(trigger) do
      {:ok, _} -> []
      _ -> [{field, "is invalid"}]
    end
  end
end
