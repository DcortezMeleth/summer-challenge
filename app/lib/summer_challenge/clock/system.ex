defmodule SummerChallenge.Clock.System do
  @moduledoc "Production clock implementation that delegates to the system clock."

  @behaviour SummerChallenge.Clock

  @impl true
  def utc_now, do: DateTime.utc_now()
end
