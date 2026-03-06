defmodule SummerChallenge.Leaderboards do
  @moduledoc """
  Context for leaderboard-related operations.

  This module provides functions for retrieving leaderboard data for public display,
  including individual leaderboards and team leaderboards.
  """

  alias SummerChallenge.Model.Types

  @doc """
  Retrieves public leaderboard data for a given sport group.

  Returns entries sorted by total distance in descending order, along with
  the timestamp of the most recent sync operation.

  ## Parameters
  - `sport_group`: One of `:running_outdoor`, `:cycling_outdoor`, `:running_virtual`, `:cycling_virtual`
  - `opts`: Optional keyword list with:
    - `:challenge_id` - Filter activities by challenge (default: nil, returns all)

  ## Returns
  - `{:ok, %{entries: [Types.leaderboard_entry_dto()], last_sync_at: DateTime.t() | nil}}`
  - `{:error, reason}`

  ## Examples
      iex> get_public_leaderboard(:running_outdoor)
      {:ok, %{entries: [...], last_sync_at: ~U[2024-01-01 12:00:00Z]}}

      iex> get_public_leaderboard(:cycling_outdoor, challenge_id: "uuid")
      {:ok, %{entries: [...], last_sync_at: ~U[2024-01-01 12:00:00Z]}}

      iex> get_public_leaderboard(:invalid)
      {:error, :invalid_sport_group}
  """
  @spec get_public_leaderboard(atom(), keyword()) ::
          {:ok, %{entries: [Types.leaderboard_entry_dto()], last_sync_at: DateTime.t() | nil}}
          | {:error, term()}
  def get_public_leaderboard(sport_group, opts \\ [])

  def get_public_leaderboard(sport_group, opts)
      when sport_group in [:running_outdoor, :cycling_outdoor, :running_virtual, :cycling_virtual] do
    import Ecto.Query

    alias SummerChallenge.Model.Activity
    alias SummerChallenge.Model.User
    alias SummerChallenge.Repo

    challenge_id = Keyword.get(opts, :challenge_id)

    # Get sport types for this group from Challenge model
    sport_types = get_sport_types_for_group(sport_group)

    # Query to aggregate activities per user
    query =
      from u in User,
        join: a in Activity,
        on: a.user_id == u.id,
        where: a.sport_type in ^sport_types and a.excluded == false,
        group_by: [u.id],
        select: %{
          user_id: u.id,
          distance_m: sum(a.distance_m),
          moving_time_s: sum(a.moving_time_s),
          elev_gain_m: sum(a.elev_gain_m),
          activity_count: count(a.id),
          last_activity_at: max(a.start_at)
        },
        order_by: [desc: sum(a.distance_m)]

    # Add challenge filter if provided
    query =
      if challenge_id do
        where(query, [_u, a], a.challenge_id == ^challenge_id)
      else
        query
      end

    results = Repo.all(query)

    # Convert results to leaderboard_entry_dto
    entries =
      results
      |> Enum.with_index(1)
      |> Enum.map(fn {row, rank} ->
        user = SummerChallenge.Accounts.get_user(row.user_id)

        %{
          rank: rank,
          sport_group: sport_group,
          user: user,
          totals: %{
            distance_m: row.distance_m,
            moving_time_s: row.moving_time_s,
            elev_gain_m: row.elev_gain_m,
            activity_count: row.activity_count
          },
          last_activity_at: row.last_activity_at
        }
      end)

    # Get the overall last sync time
    last_sync_at =
      User
      |> select([u], max(u.last_synced_at))
      |> Repo.one()

    {:ok, %{entries: entries, last_sync_at: last_sync_at}}
  end

  def get_public_leaderboard(_invalid_group, _opts) do
    {:error, :invalid_sport_group}
  end

  # Maps sport groups to their corresponding sport types (aligns with Challenge model)
  defp get_sport_types_for_group(:running_outdoor), do: ["Run", "TrailRun"]
  defp get_sport_types_for_group(:cycling_outdoor), do: ["Ride", "GravelRide", "MountainBikeRide"]
  defp get_sport_types_for_group(:running_virtual), do: ["VirtualRun"]
  defp get_sport_types_for_group(:cycling_virtual), do: ["VirtualRide"]

  @doc """
  Retrieves team leaderboard data for a given sport group.

  Only teams with at least one qualifying activity are included.
  Returns team entries sorted by total distance in descending order,
  along with the timestamp of the most recent sync operation.

  ## Parameters
  - `sport_group`: One of `:running_outdoor`, `:cycling_outdoor`, `:running_virtual`, `:cycling_virtual`
  - `opts`: Optional keyword list with:
    - `:challenge_id` - Filter activities by challenge (default: nil, returns all)

  ## Returns
  - `{:ok, %{entries: [Types.team_leaderboard_entry_dto()], last_sync_at: DateTime.t() | nil}}`
  - `{:error, reason}`
  """
  @spec get_team_leaderboard(atom(), keyword()) ::
          {:ok, %{entries: [Types.team_leaderboard_entry_dto()], last_sync_at: DateTime.t() | nil}}
          | {:error, term()}
  def get_team_leaderboard(sport_group, opts \\ [])

  def get_team_leaderboard(sport_group, opts)
      when sport_group in [:running_outdoor, :cycling_outdoor, :running_virtual, :cycling_virtual] do
    import Ecto.Query

    alias SummerChallenge.Model.Activity
    alias SummerChallenge.Model.Team
    alias SummerChallenge.Model.User
    alias SummerChallenge.Repo

    challenge_id = Keyword.get(opts, :challenge_id)
    sport_types = get_sport_types_for_group(sport_group)

    query =
      from t in Team,
        join: u in User,
        on: u.team_id == t.id,
        join: a in Activity,
        on: a.user_id == u.id,
        where: a.sport_type in ^sport_types and a.excluded == false,
        group_by: [t.id, t.name],
        select: %{
          team_id: t.id,
          team_name: t.name,
          distance_m: sum(a.distance_m),
          moving_time_s: sum(a.moving_time_s),
          elev_gain_m: sum(a.elev_gain_m),
          activity_count: count(a.id)
        },
        order_by: [desc: sum(a.distance_m)]

    query =
      if challenge_id do
        where(query, [_t, _u, a], a.challenge_id == ^challenge_id)
      else
        query
      end

    results = Repo.all(query)

    entries =
      results
      |> Enum.with_index(1)
      |> Enum.map(fn {row, rank} ->
        %{
          rank: rank,
          team: %{id: row.team_id, name: row.team_name},
          totals: %{
            distance_m: row.distance_m,
            moving_time_s: row.moving_time_s,
            elev_gain_m: row.elev_gain_m,
            activity_count: row.activity_count
          }
        }
      end)

    last_sync_at =
      User
      |> select([u], max(u.last_synced_at))
      |> Repo.one()

    {:ok, %{entries: entries, last_sync_at: last_sync_at}}
  end

  def get_team_leaderboard(_invalid_group, _opts) do
    {:error, :invalid_sport_group}
  end
end
