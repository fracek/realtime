defmodule Realtime.Workflows.Execution do
  @moduledoc """
  A workflow execution, starts the workflow with the given arguments.

  ## Fields

   * `id`: the execution unique id.
   * `arguments`: a JSON dictionary containing the arguments passed to the workflow starting state, or the specified state.
   * `start_state`: optional field to override the workflow starting state.
   * `execution_type`: the execution type, either `:persistent` or `:transient`. Persistent executions are guaranteed to
     finish, while transient executions are not.
   * `log_type`: how to log execution events, `:none` if events are not logged, or `:postgres` if events are logged to
     the same postgres database as the one containing this table.
   * `workflow`: the workflow this execution executed.

  ## Execution Type

  ### Persistent Execution

  Persistent executions are guaranteed to finish (either successfully or with an error), they achieve this by running
  as a Oban job. The tradeoff is that each execution generates at least three updates to the database (one to insert
  the Oban job, one to update its status to running, and one to update its status to completed), which could be not
  desirable for some use cases.

  ### Transient Execution

  Transient executions are not guaranteed to be run to completion. If, for example, the realtime application is
  restarted while the workflow execution is in progress, the execution will not be restarted together with the
  application. The advantage of transient executions is that they do not write additional to the database (except the
  data required to store the execution and, optionally, event logs). Transient executions should be used for low-value
  or frequent events.

  ## Log Type

  The workflow interpreter generates a number of events for each state, these events can be optionally logged to the
  database. If the execution `log_type` is set to `:postgres`, the interpreter stores the execution events to the
  same Postgres database that contains the executions table. Logging events is useful when debugging workflows.
  """
  use Ecto.Schema

  alias Ecto.Changeset

  @schema_prefix Application.get_env(:realtime, :workflows_db_schema)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  @required_fields ~w(arguments)a
  @optional_fields ~w(start_state execution_type log_type)a

  schema "executions" do
    field :start_state, :string
    field :arguments, :map
    field :execution_type, Ecto.Enum, values: [:persistent, :transient]
    field :log_type, Ecto.Enum, values: [:none, :postgres]

    timestamps()

    belongs_to :workflow, Realtime.Workflows.Workflow, type: Ecto.UUID
  end

  @doc false
  def changeset(execution, params \\ %{}) do
    execution
    |> Changeset.cast(params, @required_fields ++ @optional_fields)
    |> Changeset.validate_required(@required_fields)
  end

  @doc false
  def put_workflow(changeset, workflow) do
    changeset
    |> Changeset.change(%{workflow_id: workflow.id})
  end

  @doc """
  Returns a transaction filter that matches this table.
  """
  def transaction_filter do
    "#{%__MODULE__{}.__meta__.prefix}:#{%__MODULE__{}.__meta__.source}"
  end
end
