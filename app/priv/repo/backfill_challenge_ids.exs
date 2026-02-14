# Script to backfill challenge_id for existing activities
# Run with: mix run priv/repo/backfill_challenge_ids.exs

import Ecto.Query
alias SummerChallenge.Repo
alias SummerChallenge.Model.{Activity, Challenge}

IO.puts("Starting challenge_id backfill for activities...")

# Get all challenges
challenges = Repo.all(Challenge)
IO.puts("Found #{length(challenges)} challenges")

# Get all activities without a challenge_id
activities_query = from(a in Activity, where: is_nil(a.challenge_id))
activities = Repo.all(activities_query)
IO.puts("Found #{length(activities)} activities without challenge_id")

# Counter for updates
updated_count = 0
skipped_count = 0

# Process each activity
for activity <- activities do
  # Find matching challenge(s) for this activity
  matching_challenge =
    Enum.find(challenges, fn challenge ->
      # Check if activity is within challenge date range
      within_date_range =
        DateTime.compare(activity.start_at, challenge.start_date) in [:gt, :eq] and
          DateTime.compare(activity.start_at, challenge.end_date) in [:lt, :eq]

      # Check if activity sport type is allowed in challenge
      sport_allowed = activity.sport_type in challenge.allowed_sport_types

      within_date_range and sport_allowed
    end)

  case matching_challenge do
    nil ->
      IO.puts(
        "  ⊘ Activity #{activity.id} (#{activity.sport_type} on #{activity.start_at}) - no matching challenge"
      )

      skipped_count = skipped_count + 1

    challenge ->
      # Update activity with challenge_id
      activity
      |> Ecto.Changeset.change(%{challenge_id: challenge.id})
      |> Repo.update!()

      IO.puts(
        "  ✓ Activity #{activity.id} (#{activity.sport_type} on #{activity.start_at}) → #{challenge.name}"
      )

      updated_count = updated_count + 1
  end
end

IO.puts("\nBackfill completed!")
IO.puts("  Updated: #{updated_count} activities")
IO.puts("  Skipped: #{skipped_count} activities (no matching challenge)")
