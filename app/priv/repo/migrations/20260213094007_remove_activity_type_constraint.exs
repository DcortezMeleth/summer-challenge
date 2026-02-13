defmodule SummerChallenge.Repo.Migrations.RemoveActivityTypeConstraint do
  use Ecto.Migration

  def up do
    drop_if_exists constraint(:activities, :activities_sport_type_check)
  end

  def down do
    # Restore the constraint with the latest set of allowed types
    create constraint(:activities, :activities_sport_type_check,
             check:
               "sport_type in ('Run','TrailRun','VirtualRun','Ride','GravelRide','MountainBikeRide','VirtualRide','EBikeRide')"
           )
  end
end
