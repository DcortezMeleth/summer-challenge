defmodule SummerChallenge.SyncServiceTest do
  use SummerChallenge.DataCase
  import Mox

  alias SummerChallenge.SyncService
  alias SummerChallenge.Model.{User, UserCredential, Activity}

  setup :verify_on_exit!

  describe "sync_user/1" do
    setup do
      user = Repo.insert!(%User{display_name: "Test User", strava_athlete_id: 123})

      # Insert credential expiring in 1 hour
      Repo.insert!(%UserCredential{
        user_id: user.id,
        access_token: "old_access_token",
        refresh_token: "refresh_token",
        expires_at:
          DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.truncate(:microsecond)
      })

      {:ok, user: user}
    end

    test "syncs activities if token is valid", %{user: user} do
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

      assert {:ok, _} = SyncService.sync_user(user)

      activity = Repo.get_by(Activity, strava_id: 1001)
      assert activity
      assert activity.distance_m == 5001
      assert activity.sport_type == "Run"

      updated_user = Repo.get(User, user.id)
      assert updated_user.last_synced_at
    end

    test "refreshes token if expired", %{user: user} do
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

      assert {:ok, _} = SyncService.sync_user(user)

      updated_user = Repo.preload(user, :credential, force: true)
      assert updated_user.credential.access_token == "new_access_token"
    end

    test "filters activities by dates and sport types", %{user: user} do
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

      assert {:ok, _} = SyncService.sync_user(user)

      assert Repo.get_by(Activity, strava_id: 1001)
      refute Repo.get_by(Activity, strava_id: 1002)
      refute Repo.get_by(Activity, strava_id: 1003)
      refute Repo.get_by(Activity, strava_id: 1004)
    end

    test "respects counting_started_at for late joiners", %{user: user} do
      # Set user as late joiner
      join_date = DateTime.from_naive!(~N[2026-07-01 12:00:00.000000], "Etc/UTC")

      user
      |> Ecto.Changeset.change(%{counting_started_at: join_date})
      |> Repo.update!()

      user = Repo.get(User, user.id) |> Repo.preload(:credential)

      SummerChallenge.OAuth.StravaMock
      |> expect(:list_activities, fn %{access_token: "old_access_token"}, params ->
        # Verify the 'after' param logic in fetch_activities:
        # after should be 2026-07-01 12:00:00 (Unix: 1782907200)
        assert params.after == DateTime.to_unix(join_date)

        {:ok,
         [
           # Before join date (should be filtered by strava query but we verify logic anyway)
           %{
             "id" => 1005,
             "type" => "Run",
             "start_date" => "2026-06-30T10:00:00Z",
             "distance" => 5000,
             "moving_time" => 1800,
             "total_elevation_gain" => 0
           },
           # After join date
           %{
             "id" => 1006,
             "type" => "Run",
             "start_date" => "2026-07-02T10:00:00Z",
             "distance" => 5000,
             "moving_time" => 1800,
             "total_elevation_gain" => 0
           }
         ]}
      end)

      assert {:ok, _} = SyncService.sync_user(user)

      # 1005 should be filtered out by upsert_activities (even if returned by Strava)
      # 1006 should be saved
      refute Repo.get_by(Activity, strava_id: 1005)
      assert Repo.get_by(Activity, strava_id: 1006)
    end
  end
end
