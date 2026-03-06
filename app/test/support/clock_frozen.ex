defmodule SummerChallenge.Clock.Frozen do
  @moduledoc """
  Test clock implementation that returns a fixed, constant datetime.

  This module is configured as the clock implementation in the test environment,
  ensuring all time-dependent code operates against a known, stable reference point
  regardless of when the tests actually run.

  The frozen datetime is chosen so that:
  - Hardcoded past dates in tests (~U[2025-..], ~U[2026-01-..]) are in the past
  - Hardcoded future dates in tests (~U[2026-06-..]) are in the future
  """

  @behaviour SummerChallenge.Clock

  @frozen_now ~U[2026-03-06 12:00:00.000000Z]

  @impl true
  def utc_now, do: @frozen_now
end
