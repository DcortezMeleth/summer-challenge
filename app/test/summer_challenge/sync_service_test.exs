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
             "start_date" => "2024-06-01T10:00:00Z",
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

    test "syncs activities if DTO map is passed", %{user: user} do
      user_dto = %{id: user.id}

      SummerChallenge.OAuth.StravaMock
      |> expect(:list_activities, fn %{access_token: "old_access_token"}, _params ->
        {:ok, []}
      end)

      assert {:ok, _} = SyncService.sync_user(user_dto)
    end
  end
end
