defmodule SummerChallenge.Repo.Migrations.AddChallengeIdToActivities do
  use Ecto.Migration

  @moduledoc """
  Adds challenge_id reference to activities table to support multiple challenges.

  Activities are associated with challenges based on:
  - Activity start time falls within challenge date range
  - Activity sport type is in challenge's allowed_sport_types

  The challenge_id is nullable to support backward compatibility and activities
  that may not belong to any challenge (e.g., outside all challenge windows).
  """

  def up do
    alter table(:activities) do
      add :challenge_id, references(:challenges, type: :uuid, on_delete: :restrict), null: true
    end

    # Index for challenge-scoped queries
    create index(:activities, [:challenge_id])

    # Composite index for challenge-scoped leaderboard queries
    # This supports queries that filter by challenge, user, sport, and time
    create index(:activities, [:challenge_id, :user_id, :sport_category, :start_at],
             where: "excluded = false",
             name: :activities_challenge_leaderboard_idx
           )

    # Composite index for challenge activity counts and aggregations
    create index(:activities, [:challenge_id, :sport_category, :excluded],
             name: :activities_challenge_sport_idx
           )
  end

  def down do
    drop index(:activities, [:challenge_id, :sport_category, :excluded],
           name: :activities_challenge_sport_idx
         )

    drop index(:activities, [:challenge_id, :user_id, :sport_category, :start_at],
           name: :activities_challenge_leaderboard_idx
         )

    drop index(:activities, [:challenge_id])

    alter table(:activities) do
      remove :challenge_id
    end
  end
end
