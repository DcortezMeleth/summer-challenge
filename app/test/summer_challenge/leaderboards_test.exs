defmodule SummerChallenge.LeaderboardsTest do
  use SummerChallenge.DataCase

  alias SummerChallenge.Leaderboards
  alias SummerChallenge.Model.{Activity, User}

  describe "get_public_leaderboard/1" do
    setup do
      user1 = Repo.insert!(%User{display_name: "User 1", strava_athlete_id: 111})
      user2 = Repo.insert!(%User{display_name: "User 2", strava_athlete_id: 222})

      # User 1 has two runs
      Repo.insert!(%Activity{
        user_id: user1.id,
        strava_id: 1,
        sport_type: "Run",
        start_at: ~U[2024-06-01 10:00:00.000000Z],
        distance_m: 5000,
        moving_time_s: 1800,
        elev_gain_m: 100
      })

      Repo.insert!(%Activity{
        user_id: user1.id,
        strava_id: 2,
        sport_type: "Run",
        start_at: ~U[2024-06-02 10:00:00.000000Z],
        distance_m: 10000,
        moving_time_s: 3600,
        elev_gain_m: 200
      })

      # User 2 has one run
      Repo.insert!(%Activity{
        user_id: user2.id,
        strava_id: 3,
        sport_type: "Run",
        start_at: ~U[2024-06-01 12:00:00.000000Z],
        distance_m: 8000,
        moving_time_s: 3000,
        elev_gain_m: 150
      })

      # User 2 has one ride
      Repo.insert!(%Activity{
        user_id: user2.id,
        strava_id: 4,
        sport_type: "Ride",
        start_at: ~U[2024-06-03 10:00:00.000000Z],
        distance_m: 30000,
        moving_time_s: 3600,
        elev_gain_m: 500
      })

      {:ok, user1: user1, user2: user2}
    end

    test "returns running leaderboard sorted by distance" do
      {:ok, %{entries: entries, last_sync_at: _}} = Leaderboards.get_public_leaderboard(:running)

      assert length(entries) == 2

      [first, second] = entries
      assert first.rank == 1
      assert first.user.display_name == "User 1"
      assert first.totals.distance_m == 15000
      assert first.totals.activity_count == 2

      assert second.rank == 2
      assert second.user.display_name == "User 2"
      assert second.totals.distance_m == 8000
      assert second.totals.activity_count == 1
    end

    test "returns cycling leaderboard" do
      {:ok, %{entries: entries, last_sync_at: _}} = Leaderboards.get_public_leaderboard(:cycling)

      assert length(entries) == 1
      [entry] = entries
      assert entry.user.display_name == "User 2"
      assert entry.totals.distance_m == 30000
    end
  end
end
