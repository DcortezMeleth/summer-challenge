defmodule SummerChallenge.Milestones do
  @moduledoc """
  Context for milestone-related operations.

  This module provides functions for retrieving users who have achieved
  specific milestones, such as the 40-hour moving time threshold.
  """

  import Ecto.Query

  alias SummerChallenge.Model.Activity
  alias SummerChallenge.Model.User
  alias SummerChallenge.Repo

  # 40 hours in seconds
  @milestone_threshold_seconds 40 * 60 * 60

  @doc """
  Retrieves users who have achieved the 40-hour milestone for a specific challenge.

  Returns users sorted alphabetically by display name, with their total moving time
  and optional achievement date (first time they crossed the threshold).

  ## Parameters
  - `opts`: Keyword list with:
    - `:challenge_id` - Filter activities by challenge (required)

  ## Returns
  - `{:ok, %{achievers: [milestone_entry()], last_sync_at: DateTime.t() | nil}}`
  - `{:error, reason}`

  ## Examples
      iex> get_milestone_achievers(challenge_id: "uuid")
      {:ok, %{achievers: [...], last_sync_at: ~U[2024-01-01 12:00:00Z]}}
  """
  @spec get_milestone_achievers(keyword()) ::
          {:ok, %{achievers: [map()], last_sync_at: DateTime.t() | nil}}
          | {:error, term()}
  def get_milestone_achievers(opts \\ []) do
    challenge_id = Keyword.get(opts, :challenge_id)

    if challenge_id do
      query =
        from u in User,
          join: a in Activity,
          on: a.user_id == u.id,
          where: a.challenge_id == ^challenge_id and a.excluded == false,
          group_by: [u.id],
          having: sum(a.moving_time_s) >= ^@milestone_threshold_seconds,
          select: %{
            user_id: u.id,
            total_moving_time_s: sum(a.moving_time_s)
          },
          order_by: [asc: u.display_name]

      results = Repo.all(query)

      achievers =
        Enum.map(results, fn row ->
          user = SummerChallenge.Accounts.get_user(row.user_id)

          %{
            user: %{
              display_name: user.display_name,
              team_name: user.team_name
            },
            total_moving_time_s: row.total_moving_time_s
          }
        end)

      # Get the overall last sync time
      last_sync_at =
        User
        |> select([u], max(u.last_synced_at))
        |> Repo.one()

      {:ok, %{achievers: achievers, last_sync_at: last_sync_at}}
    else
      {:error, :challenge_id_required}
    end
  end

  @doc """
  Returns the milestone threshold in seconds.
  """
  @spec milestone_threshold_seconds() :: integer()
  def milestone_threshold_seconds, do: @milestone_threshold_seconds

  @doc """
  Returns the milestone threshold in hours.
  """
  @spec milestone_threshold_hours() :: integer()
  def milestone_threshold_hours, do: div(@milestone_threshold_seconds, 3600)
end
