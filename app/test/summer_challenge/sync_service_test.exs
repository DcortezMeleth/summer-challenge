defmodule SummerChallenge.SyncServiceTest do
  use SummerChallenge.DataCase
  import Mox

  alias SummerChallenge.SyncService
  alias SummerChallenge.Challenges
  alias SummerChallenge.Model.{User, UserCredential, Activity}

  setup :verify_on_exit!

  describe "sync_user/1" do
    setup do
      # Create a challenge for testing
      {:ok, challenge} =
        Challenges.create_challenge(%{
          name: "Test Challenge",
          start_date: ~U[2026-01-01 00:00:00Z],
          end_date: ~U[2026-12-31 23:59:59Z],
          allowed_sport_types: ["Run", "TrailRun", "Ride", "GravelRide", "MountainBikeRide"],
          status: "active"
        })

      user = Repo.insert!(%User{display_name: "Test User", strava_athlete_id: 123})

      # Insert credential expiring in 1 hour
      Repo.insert!(%UserCredential{
        user_id: user.id,
        access_token: "old_access_token",
        refresh_token: "refresh_token",
        expires_at:
          DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.truncate(:microsecond)
      })

      {:ok, user: user, challenge: challenge}
    end

    test "syncs activities if token is valid", %{user: user, challenge: challenge} do
      user = Repo.preload(user, :credential)

      SummerChallenge.OAuth.StravaMock
      |> expect(:list_activities, fn %{access_token: "old_access_token"}, _params ->
        {:ok,
         [
           %{
             "id" => 1001,
             "type" => "Run",
             "start_date" => "2026-06-01T10:00:00Z",
             "distance" => 5000.5,
             "moving_time" => 1800,
             "total_elevation_gain" => 100.2
           }
         ]}
      end)

      assert {:ok, _} = SyncService.sync_user(user, challenge)

      activity = Repo.get_by(Activity, strava_id: 1001)
      assert activity
      assert activity.distance_m == 5001
      assert activity.sport_type == "Run"
      assert activity.challenge_id == challenge.id

      updated_user = Repo.get(User, user.id)
      assert updated_user.last_synced_at
    end

    test "refreshes token if expired", %{user: user, challenge: challenge} do
      # Set token to expired
      user = Repo.preload(user, :credential)

      user.credential
      |> Ecto.Changeset.change(%{expires_at: DateTime.utc_now() |> DateTime.add(-3600, :second)})
      |> Repo.update!()

      # Reload user to get the updated credential
      user = Repo.get(User, user.id) |> Repo.preload(:credential)

      SummerChallenge.OAuth.StravaMock
      |> expect(:refresh_token, fn "refresh_token" ->
        {:ok,
         %{
           "access_token" => "new_access_token",
           "refresh_token" => "new_refresh_token",
           "expires_at" => DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()
         }}
      end)
      |> expect(:list_activities, fn %{access_token: "new_access_token"}, _params ->
        {:ok, []}
      end)

      assert {:ok, _} = SyncService.sync_user(user, challenge)

      updated_user = Repo.preload(user, :credential, force: true)
      assert updated_user.credential.access_token == "new_access_token"
    end

    test "filters activities by dates and sport types", %{user: user, challenge: challenge} do
      user = Repo.preload(user, :credential)

      SummerChallenge.OAuth.StravaMock
      |> expect(:list_activities, fn %{access_token: "old_access_token"}, _params ->
        {:ok,
         [
           # Valid
           %{
             "id" => 1001,
             "type" => "Run",
             "start_date" => "2026-06-01T10:00:00Z",
             "distance" => 5000,
             "moving_time" => 1800,
             "total_elevation_gain" => 0
           },
           # Too early
           %{
             "id" => 1002,
             "type" => "Run",
             "start_date" => "2025-12-31T23:59:59Z",
             "distance" => 5000,
             "moving_time" => 1800,
             "total_elevation_gain" => 0
           },
           # Too late
           %{
             "id" => 1003,
             "type" => "Run",
             "start_date" => "2027-01-01T00:00:00Z",
             "distance" => 5000,
             "moving_time" => 1800,
             "total_elevation_gain" => 0
           },
           # Disallowed sport type (Walk)
           %{
             "id" => 1004,
             "type" => "Walk",
             "start_date" => "2026-06-02T10:00:00Z",
             "distance" => 3000,
             "moving_time" => 3600,
             "total_elevation_gain" => 0
           }
         ]}
      end)

      assert {:ok, _} = SyncService.sync_user(user, challenge)

      assert Repo.get_by(Activity, strava_id: 1001)
      refute Repo.get_by(Activity, strava_id: 1002)
      refute Repo.get_by(Activity, strava_id: 1003)
      refute Repo.get_by(Activity, strava_id: 1004)
    end

    test "uses default challenge when no challenge is provided", %{user: user} do
      user = Repo.preload(user, :credential)

      SummerChallenge.OAuth.StravaMock
      |> expect(:list_activities, fn %{access_token: "old_access_token"}, _params ->
        {:ok,
         [
           %{
             "id" => 2001,
             "type" => "Run",
             "start_date" => "2026-06-01T10:00:00Z",
             "distance" => 5000,
             "moving_time" => 1800,
             "total_elevation_gain" => 50
           }
         ]}
      end)

      # Call sync_user with just the user (no challenge argument)
      # This simulates the production scenario when refresh button is clicked
      assert {:ok, _} = SyncService.sync_user(user)

      activity = Repo.get_by(Activity, strava_id: 2001)
      assert activity
      assert activity.sport_type == "Run"
      # Verify it used the default challenge
      assert activity.challenge_id
    end

    test "uses default challenge when called with user_id", %{user: user} do
      SummerChallenge.OAuth.StravaMock
      |> expect(:list_activities, fn %{access_token: "old_access_token"}, _params ->
        {:ok,
         [
           %{
             "id" => 3001,
             "type" => "Ride",
             "start_date" => "2026-06-02T10:00:00Z",
             "distance" => 10_000,
             "moving_time" => 2400,
             "total_elevation_gain" => 200
           }
         ]}
      end)

      # Call sync_user with just the user_id (as done in LeaderboardLive)
      assert {:ok, _} = SyncService.sync_user(user.id)

      activity = Repo.get_by(Activity, strava_id: 3001)
      assert activity
      assert activity.sport_type == "Ride"
      assert activity.challenge_id
    end
  end

  describe "sync_all/0" do
    setup do
      # Create an active challenge (will be selected as default)
      {:ok, challenge} =
        Challenges.create_challenge(%{
          name: "Active Challenge",
          start_date: DateTime.utc_now() |> DateTime.add(-7, :day),
          end_date: DateTime.utc_now() |> DateTime.add(7, :day),
          allowed_sport_types: ["Run", "Ride"],
          status: "active"
        })

      user1 = Repo.insert!(%User{display_name: "User 1", strava_athlete_id: 1001})
      user2 = Repo.insert!(%User{display_name: "User 2", strava_athlete_id: 1002})

      Repo.insert!(%UserCredential{
        user_id: user1.id,
        access_token: "token1",
        refresh_token: "refresh1",
        expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
      })

      Repo.insert!(%UserCredential{
        user_id: user2.id,
        access_token: "token2",
        refresh_token: "refresh2",
        expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
      })

      {:ok, challenge: challenge, user1: user1, user2: user2}
    end

    test "syncs all users using default challenge", %{challenge: challenge} do
      SummerChallenge.OAuth.StravaMock
      |> expect(:list_activities, 2, fn %{access_token: _token}, _params ->
        {:ok,
         [
           %{
             "id" => :rand.uniform(100_000),
             "type" => "Run",
             "start_date" => DateTime.utc_now() |> DateTime.to_iso8601(),
             "distance" => 5000,
             "moving_time" => 1800,
             "total_elevation_gain" => 100
           }
         ]}
      end)

      result = SyncService.sync_all()

      assert result.total == 2
      assert result.success == 2
      assert result.error == 0

      # Verify activities were created with the default challenge
      activities = Repo.all(Activity)
      assert length(activities) == 2
      assert Enum.all?(activities, &(&1.challenge_id == challenge.id))
    end

    test "returns error when no default challenge exists" do
      # Delete all challenges
      Repo.delete_all(SummerChallenge.Model.Challenge)

      result = SyncService.sync_all()

      assert {:error, :no_challenges} = result
    end
  end
end
