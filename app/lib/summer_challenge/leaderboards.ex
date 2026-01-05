defmodule SummerChallenge.Leaderboards do
  @moduledoc """
  Context for leaderboard-related operations.

  This module provides functions for retrieving leaderboard data for public display,
  including individual leaderboards and team leaderboards.
  """

  alias SummerChallenge.Model.Types

  @doc """
  Retrieves public leaderboard data for a given sport category.

  Returns entries sorted by total distance in descending order, along with
  the timestamp of the most recent sync operation.

  ## Parameters
  - `sport_category`: Either "run" or "ride"

  ## Returns
  - `{:ok, %{entries: [Types.leaderboard_entry_dto()], last_sync_at: DateTime.t() | nil}}`
  - `{:error, reason}`

  ## Examples
      iex> get_public_leaderboard("run")
      {:ok, %{entries: [...], last_sync_at: ~U[2024-01-01 12:00:00Z]}}

      iex> get_public_leaderboard("invalid")
      {:error, :invalid_sport_category}
  """
  @spec get_public_leaderboard(:running | :cycling) ::
          {:ok, %{entries: [Types.leaderboard_entry_dto()], last_sync_at: DateTime.t() | nil}}
          | {:error, term()}
  def get_public_leaderboard(sport_category) when sport_category in [:running, :cycling] do
    # Convert UI atoms to database atoms
    db_category = case sport_category do
      :running -> :run
      :cycling -> :ride
    end
    # For now, return mock data until we implement the actual query
    # TODO: Implement actual database query
    mock_entries = [
      %{
        rank: 1,
        sport_category: db_category,
        user: %{
          id: "550e8400-e29b-41d4-a716-446655440000",
          display_name: "Alice Runner",
          is_admin: false,
          team_id: "550e8400-e29b-41d4-a716-446655440001",
          team_name: "Fast Team",
          joined_at: ~U[2024-06-01 10:00:00Z],
          counting_started_at: ~U[2024-06-01 10:00:00Z],
          last_synced_at: ~U[2024-12-20 12:00:00Z],
          last_sync_error: nil,
          joined_late: false
        },
        totals: %{
          distance_m: 150_000, # 150km
          moving_time_s: 36_000, # 10 hours
          elev_gain_m: 2_500,
          activity_count: 15
        },
        last_activity_at: ~U[2024-12-20 08:00:00Z]
      },
      %{
        rank: 2,
        sport_category: db_category,
        user: %{
          id: "550e8400-e29b-41d4-a716-446655440002",
          display_name: "Bob Cyclist",
          is_admin: false,
          team_id: nil,
          team_name: nil,
          joined_at: ~U[2024-06-15 14:30:00Z],
          counting_started_at: ~U[2024-06-15 14:30:00Z],
          last_synced_at: ~U[2024-12-20 12:00:00Z],
          last_sync_error: nil,
          joined_late: false
        },
        totals: %{
          distance_m: 120_000, # 120km
          moving_time_s: 28_800, # 8 hours
          elev_gain_m: 1_800,
          activity_count: 12
        },
        last_activity_at: ~U[2024-12-19 16:00:00Z]
      }
    ]

    # Mock last sync time
    last_sync_at = ~U[2024-12-20 12:00:00Z]

    {:ok, %{entries: mock_entries, last_sync_at: last_sync_at}}
  end

  def get_public_leaderboard(_invalid_category) do
    {:error, :invalid_sport_category}
  end

  @doc """
  Retrieves team leaderboard data for a given sport category.

  Returns team entries sorted by total distance in descending order.

  ## Parameters
  - `sport_category`: Either "run" or "ride"

  ## Returns
  - `{:ok, [Types.team_leaderboard_entry_dto()]}`
  - `{:error, reason}`
  """
  @spec get_team_leaderboard(:running | :cycling) ::
          {:ok, [Types.team_leaderboard_entry_dto()]}
          | {:error, term()}
  def get_team_leaderboard(sport_category) when sport_category in [:running, :cycling] do
    # TODO: Implement team leaderboard query
    {:ok, []}
  end

  def get_team_leaderboard(_invalid_category) do
    {:error, :invalid_sport_category}
  end
end
