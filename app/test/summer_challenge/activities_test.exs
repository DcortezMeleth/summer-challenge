defmodule SummerChallenge.ActivitiesTest do
  use SummerChallenge.DataCase

  alias SummerChallenge.{Activities, Challenges, Repo}
  alias SummerChallenge.Model.{User, Activity}

  describe "get_user_activities/2" do
    setup do
      user =
        Repo.insert!(%User{
          display_name: "Test User",
          strava_athlete_id: 12_345,
          joined_at: DateTime.utc_now()
        })

      {:ok, challenge} =
        Challenges.create_challenge(%{
          name: "Test Challenge",
          start_date: DateTime.add(DateTime.utc_now(), -30, :day),
          end_date: DateTime.add(DateTime.utc_now(), 30, :day),
          allowed_sport_types: ["Run", "TrailRun", "Ride"],
          status: "active"
        })

      %{user: user, challenge: challenge}
    end

    test "returns activities for a user and challenge", %{user: user, challenge: challenge} do
      # Create activities for this challenge
      activity1 =
        Repo.insert!(%Activity{
          user_id: user.id,
          challenge_id: challenge.id,
          strava_id: 1,
          sport_type: "Run",
          start_at: DateTime.add(DateTime.utc_now(), -5, :day),
          distance_m: 5000,
          moving_time_s: 1800,
          elev_gain_m: 50,
          excluded: false
        })

      activity2 =
        Repo.insert!(%Activity{
          user_id: user.id,
          challenge_id: challenge.id,
          strava_id: 2,
          sport_type: "Ride",
          start_at: DateTime.add(DateTime.utc_now(), -3, :day),
          distance_m: 20_000,
          moving_time_s: 3600,
          elev_gain_m: 200,
          excluded: false
        })

      {:ok, activities} = Activities.get_user_activities(user.id, challenge.id)

      assert length(activities) == 2

      # Should be sorted by start_at descending (most recent first)
      assert Enum.at(activities, 0).id == activity2.id
      assert Enum.at(activities, 1).id == activity1.id
    end

    test "only returns activities for the specified challenge", %{
      user: user,
      challenge: challenge
    } do
      # Create another challenge
      {:ok, other_challenge} =
        Challenges.create_challenge(%{
          name: "Other Challenge",
          start_date: DateTime.add(DateTime.utc_now(), -60, :day),
          end_date: DateTime.add(DateTime.utc_now(), -31, :day),
          allowed_sport_types: ["Run"],
          status: "archived"
        })

      # Activity for the first challenge
      _activity1 =
        Repo.insert!(%Activity{
          user_id: user.id,
          challenge_id: challenge.id,
          strava_id: 1,
          sport_type: "Run",
          start_at: DateTime.add(DateTime.utc_now(), -5, :day),
          distance_m: 5000,
          moving_time_s: 1800,
          elev_gain_m: 50
        })

      # Activity for the other challenge
      _activity2 =
        Repo.insert!(%Activity{
          user_id: user.id,
          challenge_id: other_challenge.id,
          strava_id: 2,
          sport_type: "Run",
          start_at: DateTime.add(DateTime.utc_now(), -40, :day),
          distance_m: 3000,
          moving_time_s: 1200,
          elev_gain_m: 30
        })

      {:ok, activities} = Activities.get_user_activities(user.id, challenge.id)

      # Should only get activity from the specified challenge
      assert length(activities) == 1
      assert hd(activities).strava_id == 1
    end

    test "only returns activities with allowed sport types", %{user: user, challenge: challenge} do
      # Activity with allowed sport type
      _activity1 =
        Repo.insert!(%Activity{
          user_id: user.id,
          challenge_id: challenge.id,
          strava_id: 1,
          sport_type: "Run",
          start_at: DateTime.add(DateTime.utc_now(), -5, :day),
          distance_m: 5000,
          moving_time_s: 1800,
          elev_gain_m: 50
        })

      # Activity with sport type not allowed in challenge
      _activity2 =
        Repo.insert!(%Activity{
          user_id: user.id,
          challenge_id: challenge.id,
          strava_id: 2,
          sport_type: "VirtualRun",
          start_at: DateTime.add(DateTime.utc_now(), -3, :day),
          distance_m: 3000,
          moving_time_s: 1200,
          elev_gain_m: 0
        })

      {:ok, activities} = Activities.get_user_activities(user.id, challenge.id)

      # Should only get activity with allowed sport type
      assert length(activities) == 1
      assert hd(activities).sport_type == "Run"
    end

    test "returns error for non-existent challenge", %{user: user} do
      fake_challenge_id = Ecto.UUID.generate()

      assert {:error, :not_found} = Activities.get_user_activities(user.id, fake_challenge_id)
    end

    test "includes excluded activities in results", %{user: user, challenge: challenge} do
      _excluded_activity =
        Repo.insert!(%Activity{
          user_id: user.id,
          challenge_id: challenge.id,
          strava_id: 1,
          sport_type: "Run",
          start_at: DateTime.add(DateTime.utc_now(), -5, :day),
          distance_m: 5000,
          moving_time_s: 1800,
          elev_gain_m: 50,
          excluded: true
        })

      {:ok, activities} = Activities.get_user_activities(user.id, challenge.id)

      assert length(activities) == 1
      assert hd(activities).excluded == true
    end
  end

  describe "toggle_activity_exclusion/2" do
    setup do
      user =
        Repo.insert!(%User{
          display_name: "Test User",
          strava_athlete_id: 12_345,
          joined_at: DateTime.utc_now()
        })

      other_user =
        Repo.insert!(%User{
          display_name: "Other User",
          strava_athlete_id: 67_890,
          joined_at: DateTime.utc_now()
        })

      activity =
        Repo.insert!(%Activity{
          user_id: user.id,
          strava_id: 1,
          sport_type: "Run",
          start_at: DateTime.utc_now(),
          distance_m: 5000,
          moving_time_s: 1800,
          elev_gain_m: 50,
          excluded: false
        })

      %{user: user, other_user: other_user, activity: activity}
    end

    test "toggles exclusion from false to true", %{user: user, activity: activity} do
      assert activity.excluded == false

      {:ok, result} = Activities.toggle_activity_exclusion(activity.id, user.id)

      assert result.excluded == true

      # Verify in database
      updated_activity = Repo.get(Activity, activity.id)
      assert updated_activity.excluded == true
    end

    test "toggles exclusion from true to false", %{user: user, activity: activity} do
      # First exclude it
      {:ok, _} = Activities.toggle_activity_exclusion(activity.id, user.id)

      # Then include it again
      {:ok, result} = Activities.toggle_activity_exclusion(activity.id, user.id)

      assert result.excluded == false

      # Verify in database
      updated_activity = Repo.get(Activity, activity.id)
      assert updated_activity.excluded == false
    end

    test "returns error for non-existent activity", %{user: user} do
      fake_activity_id = Ecto.UUID.generate()

      assert {:error, :not_found} =
               Activities.toggle_activity_exclusion(fake_activity_id, user.id)
    end

    test "returns error when user tries to toggle another user's activity", %{
      other_user: other_user,
      activity: activity
    } do
      assert {:error, :unauthorized} =
               Activities.toggle_activity_exclusion(activity.id, other_user.id)

      # Verify activity was not modified
      unchanged_activity = Repo.get(Activity, activity.id)
      assert unchanged_activity.excluded == false
    end
  end
end
