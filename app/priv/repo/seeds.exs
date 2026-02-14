# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SummerChallenge.Repo.insert!(%SummerChallenge.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query
alias SummerChallenge.{Repo, Challenges}
alias SummerChallenge.Model.Challenge

# Clear existing challenges if any (for development)
Repo.delete_all(Challenge)

IO.puts("Creating sample challenges...")

# Create an active challenge (ongoing)
{:ok, _active_challenge} = Challenges.create_challenge(%{
  name: "Summer Challenge 2026",
  start_date: DateTime.add(DateTime.utc_now(), -10, :day),
  end_date: DateTime.add(DateTime.utc_now(), 20, :day),
  allowed_sport_types: ["Run", "TrailRun", "Ride", "GravelRide", "MountainBikeRide"],
  status: "active"
})

IO.puts("  ✓ Created: Summer Challenge 2026 (Active)")

# Create a future challenge (inactive)
{:ok, _future_challenge} = Challenges.create_challenge(%{
  name: "Fall Challenge 2026",
  start_date: DateTime.add(DateTime.utc_now(), 60, :day),
  end_date: DateTime.add(DateTime.utc_now(), 150, :day),
  allowed_sport_types: ["Run", "TrailRun", "VirtualRun", "Ride", "VirtualRide"],
  status: "inactive"
})

IO.puts("  ✓ Created: Fall Challenge 2026 (Future)")

# Create a past challenge (can be archived)
{:ok, past_challenge} = Challenges.create_challenge(%{
  name: "Spring Challenge 2026",
  start_date: DateTime.add(DateTime.utc_now(), -90, :day),
  end_date: DateTime.add(DateTime.utc_now(), -10, :day),
  allowed_sport_types: ["Run", "TrailRun", "Ride"],
  status: "active"
})

IO.puts("  ✓ Created: Spring Challenge 2026 (Past)")

# Archive the past challenge
{:ok, _archived} = Challenges.archive_challenge(past_challenge)
IO.puts("  ✓ Archived: Spring Challenge 2026")

# Create another inactive challenge
{:ok, _winter_challenge} = Challenges.create_challenge(%{
  name: "Winter Challenge 2026",
  start_date: DateTime.add(DateTime.utc_now(), 180, :day),
  end_date: DateTime.add(DateTime.utc_now(), 270, :day),
  allowed_sport_types: ["VirtualRun", "VirtualRide"],
  status: "inactive"
})

IO.puts("  ✓ Created: Winter Challenge 2026 (Future)")

IO.puts("\nSeeds completed successfully!")
IO.puts("Total challenges: #{Repo.aggregate(Challenge, :count)}")
IO.puts("Active challenges: #{Repo.aggregate(from(c in Challenge, where: c.status != "archived"), :count)}")
