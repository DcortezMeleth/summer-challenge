defmodule SummerChallenge.Model.Team do
  @moduledoc """
  Team schema and changeset functions.

  Represents a team in the Summer Challenge for group competitions.
  Teams have owners and can have multiple members.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "teams" do
    field :name, :string

    belongs_to :owner, SummerChallenge.Model.User, foreign_key: :owner_user_id

    has_many :members, SummerChallenge.Model.User, foreign_key: :team_id

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Changeset for creating a new team.

  Validates team name length and uniqueness.
  """
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :owner_user_id])
    |> validate_required([:name, :owner_user_id])
    |> validate_length(:name, min: 1, max: 80)
    |> validate_change(:name, fn :name, value ->
      trimmed = String.trim(value)

      if trimmed == "" do
        [name: "Team name cannot be blank"]
      else
        []
      end
    end)
    |> put_change(:name, String.trim(get_field(team, :name) || ""))
    |> unique_constraint(:name)
  end

  @doc """
  Changeset for renaming an existing team.

  Validates team name length and uniqueness.
  """
  def rename_changeset(team, attrs) do
    team
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 80)
    |> validate_change(:name, fn :name, value ->
      trimmed = String.trim(value)

      if trimmed == "" do
        [name: "Team name cannot be blank"]
      else
        []
      end
    end)
    |> put_change(:name, String.trim(get_field(team, :name) || ""))
    |> unique_constraint(:name)
  end
end
