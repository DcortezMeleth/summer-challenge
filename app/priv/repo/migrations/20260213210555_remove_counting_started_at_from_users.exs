defmodule SummerChallenge.Repo.Migrations.RemoveCountingStartedAtFromUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove :counting_started_at
    end
  end

  def down do
    alter table(:users) do
      add :counting_started_at, :timestamptz
    end
  end
end
