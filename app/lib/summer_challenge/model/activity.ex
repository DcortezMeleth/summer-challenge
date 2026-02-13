defmodule SummerChallenge.Model.Activity do
  @moduledoc """
  Activity schema and changeset functions.

  Represents a physical activity (e.g., Run, Ride) fetched from Strava.
  Includes generated sport category and total metrics used for leaderboards.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "activities" do
    field :strava_id, :integer
    field :sport_type, :string
    field :start_at, :utc_datetime_usec
    field :distance_m, :integer
    field :moving_time_s, :integer
    field :elev_gain_m, :integer
    field :excluded, :boolean, default: false
    field :sport_category, :string

    belongs_to :user, SummerChallenge.Model.User

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating or updating an activity.
  """
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [
      :user_id,
      :strava_id,
      :sport_type,
      :start_at,
      :distance_m,
      :moving_time_s,
      :elev_gain_m,
      :excluded
    ])
    |> validate_required([
      :user_id,
      :strava_id,
      :sport_type,
      :start_at,
      :distance_m,
      :moving_time_s,
      :elev_gain_m
    ])
    |> unique_constraint(:strava_id)
    |> foreign_key_constraint(:user_id)
  end
end
