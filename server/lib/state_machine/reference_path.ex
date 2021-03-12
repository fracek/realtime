defmodule StateMachine.ReferencePath do
  @moduledoc """
  A Reference Path is a Path with the syntax limited to identify a single node.
  """

  @opaque t :: module()

  defstruct [:inner]

  def create(path) do
    with {:ok, inner} <- Warpath.Expression.compile(path) do
      {:ok, %__MODULE__{inner: inner}}
    end
  end

  def apply(%__MODULE__{inner: inner}, document, args) do
    case inner.tokens do
      [root: "$"] -> {:ok, document}
      _ -> {:error, "ReferencePath.apply not implemented"}
    end
  end

  def query(%__MODULE__{inner: inner}, document) do
    case Warpath.query(document, inner, result_type: :value_path_tokens) do
      {:ok, {value, _}} -> {:ok, value}
      {:ok, [_]} -> {:error, "Reference Path must return a single node"}
      error -> error
    end
  end
end
