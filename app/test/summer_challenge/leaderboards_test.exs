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
        distance_m: 10_000,
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
        distance_m: 30_000,
        moving_time_s: 3600,
        elev_gain_m: 500
      })

      {:ok, user1: user1, user2: user2}
    end

    test "returns running outdoor leaderboard sorted by distance" do
      {:ok, %{entries: entries, last_sync_at: _}} =
        Leaderboards.get_public_leaderboard(:running_outdoor)

      assert length(entries) == 2

      [first, second] = entries
      assert first.rank == 1
      assert first.user.display_name == "User 1"
      assert first.totals.distance_m == 15_000
      assert first.totals.activity_count == 2

      assert second.rank == 2
      assert second.user.display_name == "User 2"
      assert second.totals.distance_m == 8000
      assert second.totals.activity_count == 1
    end

    test "returns cycling outdoor leaderboard" do
      {:ok, %{entries: entries, last_sync_at: _}} =
        Leaderboards.get_public_leaderboard(:cycling_outdoor)

      assert length(entries) == 1
      [entry] = entries
      assert entry.user.display_name == "User 2"
      assert entry.totals.distance_m == 30_000
    end

    test "separates virtual activities from outdoor activities" do
      user = Repo.insert!(%User{display_name: "Virtual Athlete", strava_athlete_id: 333})

      # Virtual Run
      Repo.insert!(%Activity{
        user_id: user.id,
        strava_id: 5,
        sport_type: "VirtualRun",
        start_at: ~U[2024-06-04 10:00:00.000000Z],
        distance_m: 5000,
        moving_time_s: 1500,
        elev_gain_m: 0
      })

      # Virtual Ride
      Repo.insert!(%Activity{
        user_id: user.id,
        strava_id: 6,
        sport_type: "VirtualRide",
        start_at: ~U[2024-06-05 10:00:00.000000Z],
        distance_m: 20_000,
        moving_time_s: 2400,
        elev_gain_m: 200
      })

      # E-Bike Ride (excluded activity type per PRD US-011)
      Repo.insert!(%Activity{
        user_id: user.id,
        strava_id: 7,
        sport_type: "EBikeRide",
        start_at: ~U[2024-06-06 10:00:00.000000Z],
        distance_m: 15_000,
        moving_time_s: 1800,
        elev_gain_m: 100
      })

      # Virtual runs appear in running_virtual, not running_outdoor
      {:ok, %{entries: outdoor_run_entries}} =
        Leaderboards.get_public_leaderboard(:running_outdoor)

      refute Enum.find(outdoor_run_entries, &(&1.user.id == user.id))

      {:ok, %{entries: virtual_run_entries}} =
        Leaderboards.get_public_leaderboard(:running_virtual)

      virtual_runner = Enum.find(virtual_run_entries, &(&1.user.id == user.id))
      assert virtual_runner.totals.distance_m == 5000

      # Virtual rides appear in cycling_virtual (e-bikes are excluded per PRD)
      {:ok, %{entries: outdoor_ride_entries}} =
        Leaderboards.get_public_leaderboard(:cycling_outdoor)

      refute Enum.find(outdoor_ride_entries, &(&1.user.id == user.id))

      {:ok, %{entries: virtual_ride_entries}} =
        Leaderboards.get_public_leaderboard(:cycling_virtual)

      virtual_cyclist = Enum.find(virtual_ride_entries, &(&1.user.id == user.id))
      # Only VirtualRide, not EBikeRide
      assert virtual_cyclist.totals.distance_m == 20_000
    end

    test "handles unknown activity types gracefully" do
      user = Repo.insert!(%User{display_name: "Generic Athlete", strava_athlete_id: 444})

      # Yoga (Unknown)
      Repo.insert!(%Activity{
        user_id: user.id,
        strava_id: 8,
        sport_type: "Yoga",
        start_at: ~U[2024-06-07 10:00:00.000000Z],
        distance_m: 0,
        moving_time_s: 3600,
        elev_gain_m: 0
      })

      # This should not appear in any leaderboards
      {:ok, %{entries: run_outdoor}} = Leaderboards.get_public_leaderboard(:running_outdoor)
      refute Enum.any?(run_outdoor, &(&1.user.id == user.id))

      {:ok, %{entries: cycle_outdoor}} = Leaderboards.get_public_leaderboard(:cycling_outdoor)
      refute Enum.any?(cycle_outdoor, &(&1.user.id == user.id))

      {:ok, %{entries: run_virtual}} = Leaderboards.get_public_leaderboard(:running_virtual)
      refute Enum.any?(run_virtual, &(&1.user.id == user.id))

      {:ok, %{entries: cycle_virtual}} = Leaderboards.get_public_leaderboard(:cycling_virtual)
      refute Enum.any?(cycle_virtual, &(&1.user.id == user.id))
    end
  end
end
