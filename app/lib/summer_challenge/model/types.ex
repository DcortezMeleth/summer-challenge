defmodule SummerChallenge.Model.Types do
  @moduledoc """
  DTO and Command Model types derived from the core database entities.

  These types map directly to the tables created in
  `priv/repo/migrations/20251107212531_create_initial_schema.exs`
  so that API contracts stay aligned with the persisted schema.
  """

  alias Ecto.UUID

  @type uuid :: UUID.t()
  @type timestamp :: DateTime.t()

  @typedoc """
  Valid sport types preserved in the `activities` table.
  """
  @type sport_type :: :Run | :TrailRun | :Ride | :GravelRide | :MountainBikeRide

  @typedoc """
  Simplified sport categories derived by the generated column in `activities.sport_category`.
  """
  @type sport_category :: :run | :ride

  @typedoc "DTO that surfaces participant information to the leaderboard and profile APIs."
  @type user_dto :: %{
          id: uuid(),
          display_name: String.t(),
          is_admin: boolean(),
          team_id: uuid() | nil,
          team_name: String.t() | nil,
          joined_at: timestamp() | nil,
          last_synced_at: timestamp() | nil,
          last_sync_error: String.t() | nil
        }

  @typedoc """
  Lightweight projection of a team that keeps the unique constraint and owner
  information intact for team-related views.
  """
  @type team_dto :: %{
          id: uuid(),
          name: String.t(),
          owner_user_id: uuid() | nil,
          member_count: non_neg_integer(),
          inserted_at: timestamp(),
          updated_at: timestamp()
        }

  @typedoc "Activity DTO mirroring the `activities` table so APIs only expose the required columns."
  @type activity_dto :: %{
          id: uuid(),
          strava_id: pos_integer(),
          user_id: uuid(),
          sport_type: sport_type(),
          sport_category: sport_category(),
          start_at: timestamp(),
          distance_m: non_neg_integer(),
          moving_time_s: non_neg_integer(),
          elev_gain_m: non_neg_integer(),
          excluded: boolean(),
          inserted_at: timestamp(),
          updated_at: timestamp()
        }

  @typedoc "Aggregated totals used by leaderboard rows."
  @type leaderboard_totals :: %{
          distance_m: non_neg_integer(),
          moving_time_s: non_neg_integer(),
          elev_gain_m: non_neg_integer(),
          activity_count: non_neg_integer()
        }

  @typedoc """
  Row representation for public leaderboards; references `users` and `teams`
  while summarizing totals for a single sport category.
  """
  @type leaderboard_entry_dto :: %{
          rank: non_neg_integer(),
          sport_category: sport_category(),
          user: user_dto(),
          totals: leaderboard_totals(),
          last_activity_at: timestamp() | nil
        }

  @typedoc "Team leaderboard entry that aggregates per-team totals per sport."
  @type team_leaderboard_entry_dto :: %{
          rank: non_neg_integer(),
          team: team_dto(),
          totals: leaderboard_totals()
        }

  @typedoc """
  40-hour milestone projection referencing participant totals from `activities`.
  """
  @type milestone_entry_dto :: %{
          user: user_dto(),
          total_moving_time_s: non_neg_integer(),
          first_achieval_at: timestamp() | nil
        }

  @typedoc "DTO for sync run metadata stored in `sync_runs`."
  @type sync_run_dto :: %{
          id: uuid(),
          started_at: timestamp(),
          finished_at: timestamp() | nil,
          status: :running | :success | :error | :cancelled,
          stats: map(),
          inserted_at: timestamp(),
          updated_at: timestamp()
        }

  @typedoc "DTO used to toggle activity exclusion flags from the My Activities page."
  @type activity_exclusion_dto :: %{
          activity: activity_dto(),
          excluded: boolean()
        }

  @typedoc "Command to create a new team while honoring the database constraints."
  @type create_team_command :: %{
          owner_user_id: uuid(),
          name: String.t(),
          max_members: pos_integer()
        }

  @typedoc "Command to add a user to an existing team."
  @type join_team_command :: %{
          team_id: uuid(),
          user_id: uuid()
        }

  @typedoc "Command to remove a user from their team before joining another."
  @type leave_team_command :: %{
          team_id: uuid(),
          user_id: uuid()
        }

  @typedoc "Command for renaming teams; keeps a reference to the actor for auditing."
  @type rename_team_command :: %{
          team_id: uuid(),
          requested_by: uuid(),
          new_name: String.t()
        }

  @typedoc "Command for deleting teams while honoring `users.team_id` cleanup logic."
  @type delete_team_command :: %{
          team_id: uuid(),
          requested_by: uuid()
        }

  @typedoc "Command that updates the display name stored on `users`."
  @type update_display_name_command :: %{
          user_id: uuid(),
          display_name: String.t()
        }

  @typedoc "Command the My Activities UI uses to toggle exclusion."
  @type toggle_activity_exclusion_command :: %{
          activity_id: uuid(),
          user_id: uuid(),
          excluded: boolean()
        }

  @typedoc "Admin command to force a sync run and surface the admin who triggered it."
  @type force_sync_command :: %{
          initiated_by: uuid(),
          reason: String.t() | nil
        }

  @typedoc "Command used to purge or disconnect user data after the challenge window."
  @type purge_user_data_command :: %{
          user_id: uuid(),
          initiated_by: uuid(),
          effective_at: timestamp()
        }
end
