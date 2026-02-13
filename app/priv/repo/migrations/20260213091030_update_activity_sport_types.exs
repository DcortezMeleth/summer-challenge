defmodule SummerChallenge.Repo.Migrations.UpdateActivitySportTypes do
  use Ecto.Migration

  def up do
    # Drop existing elements to recreate them with updated logic
    execute("ALTER TABLE activities DROP COLUMN sport_category")
    drop_if_exists constraint(:activities, :activities_sport_type_check)

    # Re-add constraint with support for virtual activities and EBikeRide
    create constraint(:activities, :activities_sport_type_check,
             check:
               "sport_type in ('Run','TrailRun','VirtualRun','Ride','GravelRide','MountainBikeRide','VirtualRide','EBikeRide')"
           )

    # Re-add generated column with updated categorization logic
    execute("""
    ALTER TABLE activities
    ADD COLUMN sport_category text GENERATED ALWAYS AS (
      CASE
        WHEN sport_type IN ('Run','TrailRun','VirtualRun') THEN 'run'
        WHEN sport_type IN ('Ride','GravelRide','MountainBikeRide','VirtualRide','EBikeRide') THEN 'ride'
        ELSE null
      END
    ) STORED
    """)
  end

  def down do
    # Rollback to original state
    execute("ALTER TABLE activities DROP COLUMN sport_category")
    drop_if_exists constraint(:activities, :activities_sport_type_check)

    create constraint(:activities, :activities_sport_type_check,
             check: "sport_type in ('Run','TrailRun','Ride','GravelRide','MountainBikeRide')"
           )

    execute("""
    ALTER TABLE activities
    ADD COLUMN sport_category text GENERATED ALWAYS AS (
      CASE
        WHEN sport_type in ('Run','TrailRun') then 'run'
        WHEN sport_type in ('Ride','GravelRide','MountainBikeRide') then 'ride'
        else null
      END
    ) STORED
    """)
  end
end
