defmodule SummerChallenge.Model.Challenge do
  @moduledoc """
  Challenge schema for managing sports competitions.

  Each challenge represents a distinct competition with configurable:
  - Date ranges (minimum 7 days enforced at database level)
  - Allowed sport types (from predefined groups)
  - Status (active, inactive, or archived)

  Challenges can overlap in time, and activities may belong to multiple challenges.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime]

  @valid_statuses ~w(active inactive archived)
  @valid_sport_types ~w(
    Run TrailRun VirtualRun
    Ride GravelRide MountainBikeRide VirtualRide
  )

  @sport_type_groups %{
    running_outdoor: ["Run", "TrailRun"],
    cycling_outdoor: ["Ride", "GravelRide", "MountainBikeRide"],
    running_virtual: ["VirtualRun"],
    cycling_virtual: ["VirtualRide"]
  }

  schema "challenges" do
    field :name, :string
    field :start_date, :utc_datetime
    field :end_date, :utc_datetime
    field :allowed_sport_types, {:array, :string}, default: []
    field :status, :string, default: "active"

    has_many :activities, SummerChallenge.Model.Activity

    timestamps()
  end

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          name: String.t() | nil,
          start_date: DateTime.t() | nil,
          end_date: DateTime.t() | nil,
          allowed_sport_types: [String.t()],
          status: String.t(),
          activities: [SummerChallenge.Model.Activity.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @doc """
  Changeset for creating or updating a challenge.

  Validates:
  - Name is required and between 1-80 characters
  - Start and end dates are required
  - End date is after start date
  - Duration is at least 7 days
  - Status is one of: active, inactive, archived
  - Sport types are from the valid list and at least one is required
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(challenge, attrs) do
    challenge
    |> cast(attrs, [:name, :start_date, :end_date, :allowed_sport_types, :status])
    |> validate_required([:name, :start_date, :end_date, :allowed_sport_types])
    |> validate_length(:name, min: 1, max: 80)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_date_range()
    |> validate_min_duration()
    |> validate_sport_types()
    |> validate_sport_types_not_empty()
    |> unique_constraint(:name)
  end

  @doc """
  Returns the valid sport type groups configuration.
  """
  @spec sport_type_groups() :: map()
  def sport_type_groups, do: @sport_type_groups

  @doc """
  Returns all valid sport types.
  """
  @spec valid_sport_types() :: [String.t()]
  def valid_sport_types, do: @valid_sport_types

  @doc """
  Returns the sport type groups that are active for this challenge.
  Returns a list of group keys (atoms) that have at least one sport type in allowed_sport_types.
  """
  @spec active_sport_groups(t()) :: [atom()]
  def active_sport_groups(%__MODULE__{allowed_sport_types: allowed_types}) do
    @sport_type_groups
    |> Enum.filter(fn {_group, types} ->
      Enum.any?(types, &(&1 in allowed_types))
    end)
    |> Enum.map(fn {group, _types} -> group end)
  end

  @doc """
  Checks if the challenge is currently active based on current time and status.
  """
  @spec active?(t()) :: boolean()
  def active?(%__MODULE__{status: "archived"}), do: false

  def active?(%__MODULE__{start_date: start_date, end_date: end_date}) do
    now = DateTime.utc_now()

    DateTime.compare(now, start_date) in [:gt, :eq] and
      DateTime.compare(now, end_date) in [:lt, :eq]
  end

  @doc """
  Checks if the challenge can be deleted (has not started yet).
  """
  @spec can_delete?(t()) :: boolean()
  def can_delete?(%__MODULE__{start_date: start_date}) do
    DateTime.compare(DateTime.utc_now(), start_date) == :lt
  end

  @doc """
  Checks if the challenge can be archived (has ended).
  """
  @spec can_archive?(t()) :: boolean()
  def can_archive?(%__MODULE__{end_date: end_date, status: status}) do
    status != "archived" and DateTime.compare(DateTime.utc_now(), end_date) == :gt
  end

  # Private validation functions

  defp validate_date_range(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && DateTime.compare(end_date, start_date) != :gt do
      add_error(changeset, :end_date, "must be after start date")
    else
      changeset
    end
  end

  defp validate_min_duration(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date do
      duration_seconds = DateTime.diff(end_date, start_date, :second)
      min_duration_seconds = 7 * 24 * 60 * 60

      if duration_seconds < min_duration_seconds do
        add_error(changeset, :end_date, "challenge must be at least 7 days long")
      else
        changeset
      end
    else
      changeset
    end
  end

  defp validate_sport_types(changeset) do
    allowed_types = get_field(changeset, :allowed_sport_types) || []

    invalid_types = Enum.reject(allowed_types, &(&1 in @valid_sport_types))

    if Enum.empty?(invalid_types) do
      changeset
    else
      add_error(
        changeset,
        :allowed_sport_types,
        "contains invalid sport types: #{Enum.join(invalid_types, ", ")}"
      )
    end
  end

  defp validate_sport_types_not_empty(changeset) do
    allowed_types = get_field(changeset, :allowed_sport_types) || []

    if Enum.empty?(allowed_types) do
      add_error(changeset, :allowed_sport_types, "must include at least one sport type")
    else
      changeset
    end
  end
end
