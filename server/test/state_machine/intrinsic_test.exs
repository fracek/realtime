defmodule StateMachine.IntrinsicTest do
  use ExUnit.Case

  alias StateMachine.Intrinsic

  describe "parse" do
    test "parses valid definitions" do
      definitions = [
        #{"States.Format('Welcome to {} {}\\'s playlist.', $.firstName, $.lastName)", nil}
      ]

      Enum.each(definitions, fn {definition, expected} ->
        {:ok, intrinsic} = Intrinsic.parse(definition)
        assert intrinsic == expected
      end)
    end
  end
end
