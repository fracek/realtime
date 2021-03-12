defmodule StateMachine.StateUtil do
  @moduledoc false

  alias StateMachine.Catcher
  alias StateMachine.Path
  alias StateMachine.PayloadTemplate
  alias StateMachine.ReferencePath
  alias StateMachine.Retrier

  ## Handle helpers

  def continue_with_result(state, result) do
    case state.transition do
      :end -> {:success, result}
      {:next, next} -> {:continue, next, result}
    end
  end

  def apply_input_path(state, args) do
    apply_path(state.input_path, args)
  end

  def apply_output_path(state, args) do
    apply_path(state.output_path, args)
  end

  def apply_parameters(state, ctx, args) do
    PayloadTemplate.apply(state.parameters, ctx.user_ctx, args)
  end

  def apply_result_selector(state, ctx, args) do
    PayloadTemplate.apply(state.result_selector, ctx.user_ctx, args)
  end

  def apply_result_path(state, ctx, args, state_args) do
    if state.result_path == nil do
      {:ok, state_args}
    else
      ReferencePath.apply(state.result_path, args, state_args)
    end
  end

  ## Parse helpers

  def parse_transition(%{"Next" => _, "End" => _}) do
    {:error, "Only one of Next or End can be present"}
  end

  def parse_transition(%{"Next" => next}) do
    {:ok, {:next, next}}
  end

  def parse_transition(%{"End" => true}) do
    {:ok, :end}
  end

  def parse_transition(_state) do
    {:error, "One of Next or End can be present"}
  end

  def parse_input_path(%{"InputPath" => path}) do
    if path == nil do
      {:ok, nil}
    else
      Path.create(path)
    end
  end

  def parse_input_path(_state) do
    Path.create("$")
  end

  def parse_parameters(%{"Parameters" => params}) do
    PayloadTemplate.create(params)
  end

  def parse_parameters(_state), do: {:ok, nil}

  def parse_result_selector(%{"ResultSelector" => params}) do
    PayloadTemplate.create(params)
  end

  def parse_result_selector(_state), do: {:ok, nil}

  def parse_result_path(%{"ResultPath" => path}) do
    if path == nil do
      {:ok, nil}
    else
      ReferencePath.create(path)
    end
  end

  def parse_result_path(_state) do
    ReferencePath.create("$")
  end

  def parse_output_path(%{"OutputPath" => path}) do
    if path == nil do
      {:ok, nil}
    else
      Path.create(path)
    end
  end

  def parse_output_path(_state) do
    Path.create("$")
  end

  def parse_retry(%{"Retry" => retries}), do: do_parse_retry(retries, [])

  def parse_retry(_retry), do: {:ok, []}

  def parse_catch(%{"Catch" => catchers}), do: do_parse_catch(catchers, [])

  def parse_catch(_retry), do: {:ok, []}

  ## Private

  defp apply_path(nil, args) do
    # If the value of InputPath is null, that means that the raw input is discarded, and the effective input for
    # the state is an empty JSON object, {}. Note that having a value of null is different from the
    # "InputPath" field being absent.

    # If the value of OutputPath is null, that means the input and result are discarded, and the effective output
    # from the state is an empty JSON object, {}.
    {:ok, %{}}
  end

  defp apply_path(path, args) do
    Path.query(path, args)
  end

  defp do_parse_retry([retrier | retriers], acc) do
    with {:ok, retrier} <- Retrier.create(retrier) do
      do_parse_retry(retriers, [retrier | acc])
    end
  end

  defp do_parse_retry([], acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp do_parse_catch([catcher | catchers], acc) do
    with {:ok, catcher} <- Catcher.create(catcher) do
      do_parse_catch(catchers, [catcher | acc])
    end
  end

  defp do_parse_catch([], acc) do
    {:ok, Enum.reverse(acc)}
  end

end
