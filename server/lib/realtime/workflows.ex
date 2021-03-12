defmodule Realtime.Workflows do
  @moduledoc """
  The Workflows context.
  """

  import Ecto.Query, warn: false
  alias Realtime.Repo

  alias Realtime.Workflows.Execution
  alias Realtime.Workflows.Workflow
  alias Realtime.Workflows.ExecutionManager

  @doc """
  Returns the list of workflows.
  """
  def list_workflows do
    Repo.all(Workflow)
  end

  @doc """
  Creates a workflow.
  """
  def create_workflow(attrs \\ %{}) do
    %Workflow{}
    |> Workflow.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the workflow with the given id.
  """
  def get_workflow(id) do
    Workflow
    |> get_or_not_found(id)
  end

  @doc """
  Updates the given workflow.
  """
  def update_workflow(workflow, attrs \\ %{}) do
    workflow
    |> Workflow.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes the given workflow.
  """
  def delete_workflow(workflow) do
    Repo.delete(workflow)
  end


  @doc """
  Invoke workflow with the given execution parameters.
  """
  def invoke_workflow(workflow, attrs \\ %{}, opts \\ []) do
    with {:ok, execution} <- create_workflow_execution(workflow, attrs) do
      ExecutionManager.start_workflow_execution(workflow, execution, opts)
    end
  end

  @doc """
  Invoke workflow with the given execution parameters and wait for its completion.
  """
  def invoke_workflow_and_wait_for_reply(workflow, attrs \\ %{}) do
    # Start and await a Task so the original self() can wait for other messages.
    # In practice this is needed to test the ExecutionController.
    task = Task.async(fn ->
      with {:ok, execution} <- invoke_workflow(workflow, attrs, reply_to: self()) do
        receive do
          {:success, msg} -> {:ok, msg, execution}
          {:failure, msg} -> {:error, msg, execution}
          err -> {:error, err, execution}
        after
          5_000 -> {:timeout, execution}
        end
      end
    end)

    Task.await(task)
  end

  def create_workflow_execution(workflow, attrs \\ %{}) do
    %Execution{}
    |> Execution.changeset(attrs)
    |> Execution.put_workflow(workflow)
    |> Repo.insert()
  end

  @doc """
  Returns the workflow execution with the given id.
  """
  def get_workflow_execution(id) do
    Execution
    |> get_or_not_found(id)
  end

  @doc """
  Returns a list of executions for the given workflow.
  """
  def list_workflow_executions(workflow_id) do
    from(Execution, where: [workflow_id: ^workflow_id])
    |> Repo.all()
  end

  @doc """
  Deletes the given workflow execution.
  """
  def delete_workflow_execution(execution) do
    Repo.delete(execution)
  end

  @doc """
  Updates the given workflow execution.
  """
  def update_workflow_execution(execution, attrs \\ %{}) do
    execution
    |> Execution.changeset(attrs)
    |> Repo.update()
  end

  ## Private

  defp get_or_not_found(queryable, id, opts \\ []) do
    case Repo.get(queryable, id, opts) do
      nil -> {:not_found, id}
      found -> {:ok, found}
    end
  end
end
