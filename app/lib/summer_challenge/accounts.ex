defmodule SummerChallenge.Accounts do
  @moduledoc """
  Context for user account operations.

  This module handles user-related business logic including onboarding,
  profile management, and authentication-related operations.
  """

  import Ecto.Query
  require Logger
  alias SummerChallenge.Repo
  alias SummerChallenge.Model.{User, Types, UserCredential}

  @doc """
  Retrieves a user by their ID.


  Returns the user as a user_dto or nil if not found.
  """
  @spec get_user(Types.uuid()) :: Types.user_dto() | nil
  def get_user(user_id) do
    User
    |> where([u], u.id == ^user_id)
    |> preload(:team)
    |> Repo.one()
    |> case do
      nil -> nil
      user -> user_to_dto(user)
    end
  end

  @doc """
  Completes the onboarding process for a new user.

  Updates the user's display name and marks them as joined if not already done.
  This is called after the user has authenticated with Strava and confirmed
  their display name.

  ## Parameters
  - `user_id`: The ID of the user completing onboarding
  - `display_name`: The chosen display name (1-80 characters)

  ## Returns
  - `{:ok, user_dto}` on success
  - `{:error, Ecto.Changeset.t()}` on validation failure
  - `{:error, :user_not_found}` if user doesn't exist
  """
  @spec complete_onboarding(Types.uuid(), String.t()) ::
          {:ok, Types.user_dto()} | {:error, Ecto.Changeset.t()} | {:error, :user_not_found}
  def complete_onboarding(user_id, display_name) do
    case Repo.get(User, user_id) do
      nil ->
        {:error, :user_not_found}

      user ->
        user
        |> User.complete_onboarding_changeset(%{display_name: display_name})
        |> Repo.update()
        |> case do
          {:ok, updated_user} ->
            {:ok, user_to_dto(updated_user)}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Checks if a user has completed onboarding.

  A user is considered onboarded if they have a display_name and joined_at timestamp.
  """
  @spec user_onboarded?(Types.user_dto()) :: boolean()
  def user_onboarded?(%{display_name: display_name, joined_at: joined_at})
      when is_binary(display_name) and display_name != "" and not is_nil(joined_at),
      do: true

  def user_onboarded?(_), do: false

  @doc """
  Finds or creates a user from Strava athlete profile.

  Creates a new user if they don't exist, or updates existing user with Strava data.
  Sets default display name and admin status.

  ## Parameters
  - `athlete`: Strava athlete profile map

  ## Returns
  - `{:ok, user_dto}` on success
  - `{:error, changeset}` on validation failure
  """
  @spec find_or_create_user_from_strava(map()) ::
          {:ok, Types.user_dto()} | {:error, Ecto.Changeset.t()}
  def find_or_create_user_from_strava(athlete) do
    strava_id = athlete["id"]

    case get_user_by_strava_id(strava_id) do
      nil ->
        # Create new user
        create_user_from_strava(athlete)

      existing_user ->
        # Update existing user (could refresh profile data in future)
        {:ok, existing_user}
    end
  end

  @doc """
  Stores OAuth credentials for a user.

  Encrypts and stores access/refresh tokens and expiration data.

  ## Parameters
  - `user_id`: The user's ID
  - `token_data`: Map with access_token, refresh_token, expires_at, token_type

  ## Returns
  - `:ok` on success
  - `{:error, term()}` on failure
  """
  @spec store_credentials(Types.uuid(), map()) :: :ok | {:error, term()}
  def store_credentials(user_id, token_data) do
    # Prepare credential attributes
    attrs = %{
      user_id: user_id,
      access_token: token_data.access_token,
      refresh_token: token_data.refresh_token,
      expires_at: DateTime.from_unix!(token_data.expires_at)
    }

    # Use upsert to handle both creation and update
    %UserCredential{}
    |> UserCredential.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:inserted_at]},
      conflict_target: :user_id
    )
    |> case do
      {:ok, _credential} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  # Private functions

  @spec get_user_by_strava_id(integer()) :: Types.user_dto() | nil
  defp get_user_by_strava_id(strava_id) do
    SummerChallenge.Model.User
    |> where([u], u.strava_athlete_id == ^strava_id)
    |> preload(:team)
    |> Repo.one()
    |> case do
      nil -> nil
      user -> user_to_dto(user)
    end
  end

  @spec create_user_from_strava(map()) :: {:ok, Types.user_dto()} | {:error, Ecto.Changeset.t()}
  defp create_user_from_strava(athlete) do
    display_name = generate_display_name(athlete)
    is_admin = check_admin_status(athlete)

    %SummerChallenge.Model.User{}
    |> Ecto.Changeset.change(%{
      strava_athlete_id: athlete["id"],
      display_name: display_name,
      is_admin: is_admin
    })
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        # Preload team association for consistency
        user = Repo.preload(user, :team)
        {:ok, user_to_dto(user)}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @spec generate_display_name(map()) :: String.t()
  defp generate_display_name(athlete) do
    # Generate display name per US-030 requirements
    first_name = athlete["firstname"]
    last_name = athlete["lastname"]

    cond do
      first_name && last_name ->
        "#{first_name} #{String.first(last_name)}."

      first_name ->
        first_name

      athlete["email"] ->
        # Use part before @ as fallback
        athlete["email"]
        |> String.split("@")
        |> List.first()
        |> Kernel.<>(" (Strava)")

      true ->
        "Athlete #{athlete["id"]}"
    end
  end

  @spec check_admin_status(map()) :: boolean()
  defp check_admin_status(athlete) do
    admin_emails =
      Application.get_env(:summer_challenge, :admin_emails, "")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)

    athlete["email"] in admin_emails
  end

  # Private functions

  @spec user_to_dto(User.t()) :: Types.user_dto()
  defp user_to_dto(user) do
    # Ensure team association is loaded before accessing it
    user = Repo.preload(user, :team)

    team_name =
      case user.team do
        %Ecto.Association.NotLoaded{} -> nil
        nil -> nil
        team -> team.name
      end

    team_id =
      case user.team do
        %Ecto.Association.NotLoaded{} -> user.team_id
        nil -> user.team_id
        team -> team.id
      end

    %{
      id: user.id,
      display_name: user.display_name,
      is_admin: user.is_admin,
      team_id: team_id,
      team_name: team_name,
      joined_at: user.joined_at,
      counting_started_at: user.counting_started_at,
      last_synced_at: user.last_synced_at,
      last_sync_error: user.last_sync_error,
      joined_late: calculate_joined_late(user)
    }
  end

  @spec calculate_joined_late(User.t()) :: boolean()
  defp calculate_joined_late(%{joined_at: joined_at, counting_started_at: counting_started_at}) do
    # A user joined late if their joined_at is after the challenge start date
    # For now, we'll consider any join after the challenge start as "late"
    # This logic will need to be updated when challenge dates are configured
    not is_nil(joined_at) and joined_at != counting_started_at
  end
end
