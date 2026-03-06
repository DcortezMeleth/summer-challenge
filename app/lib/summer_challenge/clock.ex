defmodule SummerChallenge.Clock do
  @moduledoc """
  Time abstraction layer that allows deterministic testing.

  In dev/prod, delegates to the system clock via `SummerChallenge.Clock.System`.
  In tests, the implementation is replaced with a Mox mock that returns a fixed
  datetime, making time-dependent tests fully independent of when they run.

  All application code should call `SummerChallenge.Clock.utc_now/0` instead of
  `DateTime.utc_now/0` directly.
  """

  @callback utc_now() :: DateTime.t()

  @doc "Returns the current UTC datetime via the configured clock implementation."
  @spec utc_now() :: DateTime.t()
  def utc_now do
    impl().utc_now()
  end

  defp impl do
    Application.get_env(:summer_challenge, :clock, SummerChallenge.Clock.System)
  end
end
