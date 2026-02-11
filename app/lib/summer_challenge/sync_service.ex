defmodule SummerChallenge.SyncService do
  @moduledoc """
  Service for synchronizing activities from Strava for all eligible users.
  """

  require Logger
  alias SummerChallenge.Accounts
  alias SummerChallenge.Repo
  alias SummerChallenge.Model.{User, Activity}

  defp strava_client, do: Application.get_env(:summer_challenge, :strava_client)

  @doc """
  Synchronizes activities for all users with credentials.
  """
  def sync_all do
    users = Accounts.list_syncable_users()
    Logger.info("Starting sync for #{length(users)} users")

    results = Enum.map(users, &sync_user/1)

    %{
      total: length(users),
      success: Enum.count(results, &match?({:ok, _}, &1)),
      error: Enum.count(results, &match?({:error, _}, &1))
    }
  end

  @doc """
  Synchronizes activities for a single user.
  Accepts a User struct, a DTO map, or a user ID.
  """
  def sync_user(%User{} = user) do
    # Ensure credential is preloaded
    case Repo.preload(user, :credential) do
      %User{credential: nil} ->
        {:error, :no_credentials}

      user ->
        with {:ok, token} <- ensure_valid_token(user),
             {:ok, activities} <- fetch_activities(user, token) do
          upsert_activities(user, activities)
          update_last_synced(user)
        else
          {:error, reason} ->
            Logger.error("Failed to sync user #{user.id}: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  def sync_user(user_id_or_dto) do
    user_id = if is_map(user_id_or_dto), do: user_id_or_dto.id, else: user_id_or_dto

    case Accounts.get_syncable_user(user_id) do
      nil -> {:error, :user_not_found}
      user -> sync_user(user)
    end
  end

  defp ensure_valid_token(%User{credential: credential} = user) do
    # buffer of 5 minutes
    if DateTime.compare(credential.expires_at, DateTime.add(DateTime.utc_now(), 300)) == :gt do
      {:ok, %{access_token: credential.access_token}}
    else
      Logger.info("Refreshing token for user #{user.id}")

      case Accounts.refresh_token(user) do
        {:ok, data} -> {:ok, %{access_token: data["access_token"]}}
        error -> error
      end
    end
  end

  defp fetch_activities(user, token) do
    # Fetch since last_synced_at or 30 days ago if never synced
    after_timestamp =
      if user.last_synced_at do
        DateTime.to_unix(user.last_synced_at)
      else
        DateTime.utc_now() |> DateTime.add(-30, :day) |> DateTime.to_unix()
      end

    strava_client().list_activities(token, %{after: after_timestamp})
  end

  defp upsert_activities(user, activities) do
    Enum.each(activities, fn activity_data ->
      attrs = %{
        user_id: user.id,
        strava_id: activity_data["id"],
        sport_type: activity_data["type"],
        start_at: activity_data["start_date"] |> parse_iso8601!(),
        distance_m: round(activity_data["distance"]),
        moving_time_s: activity_data["moving_time"],
        elev_gain_m: round(activity_data["total_elevation_gain"] || 0)
      }

      %Activity{}
      |> Activity.changeset(attrs)
      |> Repo.insert(
        on_conflict:
          {:replace_all_except, [:id, :inserted_at, :user_id, :strava_id, :sport_category]},
        conflict_target: :strava_id
      )
    end)
  end

  defp update_last_synced(user) do
    user
    |> Ecto.Changeset.change(%{last_synced_at: DateTime.utc_now()})
    |> Repo.update()
  end

  defp parse_iso8601!(binary) do
    {:ok, dt, _} = DateTime.from_iso8601(binary)
    dt
  end
end
