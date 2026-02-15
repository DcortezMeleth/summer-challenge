defmodule SummerChallenge.SyncService do
  @moduledoc """
  Service for synchronizing activities from Strava for all eligible users.
  """

  require Logger
  alias SummerChallenge.Accounts
  alias SummerChallenge.Repo
  alias SummerChallenge.Challenges
  alias SummerChallenge.Model.{User, Activity, Challenge}

  defp strava_client, do: Application.get_env(:summer_challenge, :strava_client)

  @doc """
  Synchronizes activities for all users with credentials.
  """
  def sync_all do
    case Challenges.get_default_challenge() do
      {:ok, %Challenge{} = challenge} ->
        users = Accounts.list_syncable_users()
        Logger.info("Starting sync for #{length(users)} users for challenge #{challenge.name}")

        results = Enum.map(users, &sync_user(&1, challenge))

        %{
          total: length(users),
          success: Enum.count(results, &match?({:ok, _}, &1)),
          error: Enum.count(results, &match?({:error, _}, &1))
        }

      {:error, reason} ->
        Logger.error("Failed to start sync: challenge not found. Reason: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Synchronizes activities for a single user.
  Accepts a User struct, a DTO map, or a user ID.
  Options can include a pre-loaded challenge.
  """
  def sync_user(user, challenge \\ nil)

  def sync_user(%User{} = user, challenge) do
    # Ensure challenge is loaded
    case maybe_get_challenge(challenge) do
      {:ok, challenge} ->
        # Ensure credential is preloaded
        case Repo.preload(user, :credential) do
          %User{credential: nil} ->
            {:error, :no_credentials}

          user ->
            with {:ok, token} <- ensure_valid_token(user),
                 {:ok, activities} <- fetch_activities(user, token, challenge) do
              upsert_activities(user, activities, challenge)
              update_last_synced(user)
            else
              {:error, reason} ->
                Logger.error("Failed to sync user #{user.id}: #{inspect(reason)}")
                {:error, reason}
            end
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def sync_user(user_id_or_dto, challenge) do
    user_id = if is_map(user_id_or_dto), do: user_id_or_dto.id, else: user_id_or_dto

    case Accounts.get_syncable_user(user_id) do
      nil -> {:error, :user_not_found}
      user -> sync_user(user, challenge)
    end
  end

  defp maybe_get_challenge(%Challenge{} = challenge), do: {:ok, challenge}
  defp maybe_get_challenge(nil), do: Challenges.get_default_challenge()

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

  defp fetch_activities(user, token, %Challenge{} = challenge) do
    # Fetch since last_synced_at or challenge.start_date
    after_timestamp =
      if user.last_synced_at do
        DateTime.to_unix(user.last_synced_at)
      else
        challenge.start_date |> DateTime.to_unix()
      end

    Logger.info("Fetching activities for user #{user.id} since #{after_timestamp}")

    case strava_client().list_activities(token, %{after: after_timestamp}) do
      {:ok, activities} ->
        Logger.info("Successfully fetched #{length(activities)} activities for user #{user.id}")
        {:ok, activities}

      {:error, reason} ->
        Logger.error("Failed to fetch activities for user #{user.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp upsert_activities(user, activities, %Challenge{} = challenge) do
    # Filter activities to only include those within the challenge window
    start_threshold = challenge.start_date

    activities
    |> Enum.filter(fn activity_data ->
      start_at = activity_data["start_date"] |> parse_iso8601!()

      # Filter by challenge window and activity type
      DateTime.compare(start_at, challenge.end_date) != :gt and
        DateTime.compare(start_at, start_threshold) != :lt and
        activity_data["type"] in challenge.allowed_sport_types
    end)
    |> Enum.each(fn activity_data ->
      attrs = %{
        user_id: user.id,
        challenge_id: challenge.id,
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
