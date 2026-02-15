defmodule SummerChallenge.Repo.Migrations.CreateChallengesTable do
  use Ecto.Migration

  @moduledoc """
  Creates the challenges table for managing multiple sports competitions.

  Each challenge represents a distinct competition with:
  - Configurable date ranges (minimum 7 days)
  - Allowed sport types (selected from predefined groups)
  - Status tracking (active/inactive/archived)

  Challenges can overlap in time, and activities may belong to multiple challenges
  based on their start time and sport type.
  """

  def up do
    create table(:challenges, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :name, :text, null: false
      add :start_date, :timestamptz, null: false
      add :end_date, :timestamptz, null: false
      add :allowed_sport_types, {:array, :text}, null: false, default: []
      add :status, :text, null: false, default: "active"
      timestamps(type: :timestamptz)
    end

    # Constraints
    create constraint(:challenges, :challenges_name_length_check,
             check: "char_length(name) between 1 and 80"
           )

    create constraint(:challenges, :challenges_status_check,
             check: "status in ('active', 'inactive', 'archived')"
           )

    create constraint(:challenges, :challenges_date_range_check, check: "end_date > start_date")

    create constraint(:challenges, :challenges_min_duration_check,
             check: "end_date >= start_date + interval '7 days'"
           )

    # Indexes
    create unique_index(:challenges, [:name])
    create index(:challenges, [:status])
    create index(:challenges, [:start_date])
    create index(:challenges, [:end_date])
    create index(:challenges, [:start_date, :end_date])
  end

  def down do
    drop table(:challenges)
  end
end
