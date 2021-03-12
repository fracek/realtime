defmodule StateMachine.Path do
  @moduledoc false

  @opaque t :: module()

  defstruct [:inner]

  def create(path) do
    with {:ok, inner} <- Warpath.Expression.compile(path) do
      {:ok, %__MODULE__{inner: inner}}
    end
  end

  def query(%__MODULE__{inner: inner}, data) do
    Warpath.query(data, inner)
  end
end
