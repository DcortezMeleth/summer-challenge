defmodule SummerChallenge.Activities do
  @moduledoc """
  Context for activity-related operations.

  This module provides functions for retrieving and managing user activities,
  including filtering by challenge and toggling activity exclusions.
  """

  import Ecto.Query
  alias SummerChallenge.Repo
  alias SummerChallenge.Model.Activity
  alias SummerChallenge.Model.Types

  @doc """
  Retrieves activities for a specific user and challenge.

  Returns activities sorted by start time (most recent first), filtered by the
  challenge's date range and allowed sport types.

  ## Parameters
  - `user_id`: The user's UUID
  - `challenge_id`: The challenge UUID to filter activities by

  ## Returns
  - `{:ok, [Types.activity_dto()]}`
  - `{:error, reason}`

  ## Examples
      iex> get_user_activities(user_id, challenge_id)
      {:ok, [%{id: "...", sport_type: "Run", ...}]}
  """
  @spec get_user_activities(binary(), binary()) ::
          {:ok, [Types.activity_dto()]} | {:error, term()}
  def get_user_activities(user_id, challenge_id) do
    # First, get the challenge to know the date range and allowed sport types
    case SummerChallenge.Challenges.get_challenge(challenge_id) do
      {:ok, challenge} ->
        activities =
          Activity
          |> where([a], a.user_id == ^user_id)
          |> where([a], a.challenge_id == ^challenge_id)
          |> where([a], a.sport_type in ^challenge.allowed_sport_types)
          |> order_by([a], desc: a.start_at)
          |> Repo.all()
          |> Enum.map(&activity_to_dto/1)

        {:ok, activities}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Toggles the exclusion status of an activity.

  Only the activity owner can toggle their own activities.

  ## Parameters
  - `activity_id`: The activity UUID
  - `user_id`: The user's UUID (for authorization)

  ## Returns
  - `{:ok, Types.activity_exclusion_dto()}`
  - `{:error, :not_found | :unauthorized | term()}`

  ## Examples
      iex> toggle_activity_exclusion(activity_id, user_id)
      {:ok, %{id: "...", excluded: true}}
  """
  @spec toggle_activity_exclusion(binary(), binary()) ::
          {:ok, Types.activity_exclusion_dto()} | {:error, term()}
  def toggle_activity_exclusion(activity_id, user_id) do
    case Repo.get(Activity, activity_id) do
      nil ->
        {:error, :not_found}

      activity ->
        if activity.user_id == user_id do
          activity
          |> Activity.changeset(%{excluded: !activity.excluded})
          |> Repo.update()
          |> case do
            {:ok, updated_activity} ->
              {:ok,
               %{
                 id: updated_activity.id,
                 excluded: updated_activity.excluded
               }}

            {:error, changeset} ->
              {:error, changeset}
          end
        else
          {:error, :unauthorized}
        end
    end
  end

  # Private functions

  defp activity_to_dto(activity) do
    %{
      id: activity.id,
      strava_id: activity.strava_id,
      sport_type: activity.sport_type,
      start_at: activity.start_at,
      distance_m: activity.distance_m,
      moving_time_s: activity.moving_time_s,
      elev_gain_m: activity.elev_gain_m,
      excluded: activity.excluded,
      sport_category: activity.sport_category
    }
  end
end
