defmodule SummerChallenge.Challenges do
  @moduledoc """
  Service for managing challenges. Currently a mock.
  """

  alias SummerChallenge.Model.Challenge

  @doc """
  Returns a challenge by ID. Currently returns a mock challenge for ID 1.
  """
  def get_challenge(1) do
    {:ok,
     %Challenge{
       id: 1,
       name: "Summer Challenge 2026",
       start_date: DateTime.from_naive!(~N[2026-01-01 00:00:00], "Etc/UTC"),
       end_date: DateTime.from_naive!(~N[2026-12-31 23:59:59], "Etc/UTC"),
       included_activity_types: [
         "Run",
         "TrailRun",
         "VirtualRun",
         "Ride",
         "GravelRide",
         "MountainBikeRide",
         "VirtualRide",
         "EBikeRide"
       ]
     }}
  end

  def get_challenge(_id), do: {:error, :not_found}
end
