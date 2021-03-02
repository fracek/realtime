defmodule StateMachine.StatesLanguage do
  @moduledoc false

  def validate(definition) do

  schema = :realtime
          |> :code.priv_dir()
          |> Path.join("schemas/state-machine.json")
          |> File.read!()
          |> Jason.decode!()
          |> ExJsonSchema.Schema.resolve()

    ExJsonSchema.Validator.validate(schema, definition)
  end
end
