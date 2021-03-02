defmodule StateMachine.SchemaResolver do
  @moduledoc """
  Resolve JSON Schema schemas from their url.

  JSON Schemas related to Amazon States Language are stored in the application priv directory, this module
  maps the url to the file and caches the results.
  """
  use Agent

  @root "http://asl-validator.cloud/"
  @root_len String.length(@root)

  require Logger

  def start_link(_args) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def resolve(url) do
    Agent.get_and_update(__MODULE__, fn state -> get_or_resolve(state, url) end)
  end

  defp get_or_resolve(state, url) do
    case Map.get(state, url) do
      nil ->
        schema = resolve_url(url)
        new_state = Map.put(state, url, schema)
        {schema, new_state}
      schema -> {schema, state}
    end
  end

  defp resolve_url(url) do
    file_name = String.slice(url, @root_len..-1)
    :realtime
    |> :code.priv_dir()
    |> Path.join("schemas/#{file_name}.json")
    |> File.read!()
    |> Jason.decode!()
  end
end
