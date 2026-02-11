defmodule SummerChallenge.Model.User do
  @moduledoc """
  User schema and changeset functions.

  Represents a participant in the Summer Challenge with their Strava integration,
  display preferences, and participation status.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :display_name, :string
    field :strava_athlete_id, :integer
    field :joined_at, :utc_datetime_usec
    field :counting_started_at, :utc_datetime_usec
    field :last_synced_at, :utc_datetime_usec
    field :last_sync_error, :string
    field :is_admin, :boolean, default: false

    belongs_to :team, SummerChallenge.Model.Team
    has_one :credential, SummerChallenge.Model.UserCredential, foreign_key: :user_id
    has_many :activities, SummerChallenge.Model.Activity

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for updating display name during onboarding.

  Validates display name length and trimming.
  """
  def display_name_changeset(user, attrs) do
    user
    |> cast(attrs, [:display_name])
    |> validate_required([:display_name])
    |> validate_length(:display_name, min: 1, max: 80)
    |> validate_change(:display_name, fn :display_name, value ->
      trimmed = String.trim(value)

      if trimmed == "" do
        [display_name: "Display name cannot be blank"]
      else
        []
      end
    end)
    |> update_change(:display_name, &String.trim/1)
  end

  @doc """
  Changeset for completing onboarding.

  Updates display name and sets joined_at timestamp if not already set.
  """
  def complete_onboarding_changeset(user, attrs) do
    user
    |> display_name_changeset(attrs)
    |> then(fn changeset ->
      if get_field(changeset, :joined_at) do
        changeset
      else
        put_change(changeset, :joined_at, DateTime.utc_now())
      end
    end)
  end
end
