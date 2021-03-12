defmodule StateMachine.Context do
  @type user_ctx :: any()

  @type t :: %__MODULE__{
               user_ctx: user_ctx(),
               resource_handler: any()
             }

  defstruct [:user_ctx, :resource_handler]

  def create(user_ctx, resource_handler) do
    %__MODULE__{
      user_ctx: user_ctx,
      resource_handler: resource_handler
    }
  end
end
