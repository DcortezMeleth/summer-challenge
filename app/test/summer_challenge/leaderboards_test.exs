defmodule SummerChallenge.LeaderboardsTest do
  use SummerChallenge.DataCase

  alias SummerChallenge.Leaderboards
  alias SummerChallenge.Model.Activity
  alias SummerChallenge.Model.User

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

      refute Enum.any?(outdoor_run_entries, &(&1.user.id == user.id))

      {:ok, %{entries: virtual_run_entries}} =
        Leaderboards.get_public_leaderboard(:running_virtual)

      virtual_runner = Enum.find(virtual_run_entries, &(&1.user.id == user.id))
      assert virtual_runner.totals.distance_m == 5000

      # Virtual rides appear in cycling_virtual (e-bikes are excluded per PRD)
      {:ok, %{entries: outdoor_ride_entries}} =
        Leaderboards.get_public_leaderboard(:cycling_outdoor)

      refute Enum.any?(outdoor_ride_entries, &(&1.user.id == user.id))

      {:ok, %{entries: virtual_ride_entries}} =
        Leaderboards.get_public_leaderboard(:cycling_virtual)

      virtual_cyclist = Enum.find(virtual_ride_entries, &(&1.user.id == user.id))
      # Only VirtualRide, not EBikeRide
      assert virtual_cyclist.totals.distance_m == 20_000
    end

    test "filters by challenge_id when provided" do
      challenge =
        Repo.insert!(%SummerChallenge.Model.Challenge{
          name: "Test Challenge",
          start_date: ~U[2024-06-01 00:00:00Z],
          end_date: ~U[2024-08-31 23:59:59Z],
          allowed_sport_types: ["Run"],
          status: "active"
        })

      # Tag user1's first activity with the challenge
      Repo.get_by!(Activity, strava_id: 1)
      |> Ecto.Changeset.change(%{challenge_id: challenge.id})
      |> Repo.update!()

      {:ok, %{entries: entries}} =
        Leaderboards.get_public_leaderboard(:running_outdoor, challenge_id: challenge.id)

      assert length(entries) == 1
      assert hd(entries).user.display_name == "User 1"
      assert hd(entries).totals.distance_m == 5000
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

  describe "get_team_leaderboard/2" do
    setup do
      alias SummerChallenge.Model.Team

      team_a = Repo.insert!(%Team{name: "Team Alpha", owner_user_id: nil})
      team_b = Repo.insert!(%Team{name: "Team Beta", owner_user_id: nil})

      runner1 =
        Repo.insert!(%User{
          display_name: "Runner A1",
          strava_athlete_id: 501,
          team_id: team_a.id
        })

      runner2 =
        Repo.insert!(%User{
          display_name: "Runner A2",
          strava_athlete_id: 502,
          team_id: team_a.id
        })

      runner3 =
        Repo.insert!(%User{
          display_name: "Runner B1",
          strava_athlete_id: 503,
          team_id: team_b.id
        })

      teamless =
        Repo.insert!(%User{display_name: "No Team", strava_athlete_id: 504})

      # Team Alpha: two members with runs (total 20 km)
      Repo.insert!(%Activity{
        user_id: runner1.id,
        strava_id: 201,
        sport_type: "Run",
        start_at: ~U[2024-06-01 08:00:00.000000Z],
        distance_m: 10_000,
        moving_time_s: 3600,
        elev_gain_m: 100
      })

      Repo.insert!(%Activity{
        user_id: runner2.id,
        strava_id: 202,
        sport_type: "TrailRun",
        start_at: ~U[2024-06-02 08:00:00.000000Z],
        distance_m: 10_000,
        moving_time_s: 4000,
        elev_gain_m: 300
      })

      # Team Beta: one member with a run (total 7 km)
      Repo.insert!(%Activity{
        user_id: runner3.id,
        strava_id: 203,
        sport_type: "Run",
        start_at: ~U[2024-06-01 10:00:00.000000Z],
        distance_m: 7_000,
        moving_time_s: 2400,
        elev_gain_m: 50
      })

      # Team Alpha member also has a ride — should not appear in running leaderboard
      Repo.insert!(%Activity{
        user_id: runner1.id,
        strava_id: 204,
        sport_type: "Ride",
        start_at: ~U[2024-06-03 10:00:00.000000Z],
        distance_m: 50_000,
        moving_time_s: 5400,
        elev_gain_m: 600
      })

      # Teamless user's activity — must not appear
      Repo.insert!(%Activity{
        user_id: teamless.id,
        strava_id: 205,
        sport_type: "Run",
        start_at: ~U[2024-06-01 12:00:00.000000Z],
        distance_m: 99_000,
        moving_time_s: 9000,
        elev_gain_m: 500
      })

      {:ok, team_a: team_a, team_b: team_b}
    end

    test "returns teams ranked by distance for the correct sport group" do
      {:ok, %{entries: entries, last_sync_at: _}} =
        Leaderboards.get_team_leaderboard(:running_outdoor)

      assert length(entries) == 2

      [first, second] = entries
      assert first.rank == 1
      assert first.team.name == "Team Alpha"
      assert first.totals.distance_m == 20_000
      assert first.totals.activity_count == 2

      assert second.rank == 2
      assert second.team.name == "Team Beta"
      assert second.totals.distance_m == 7_000
      assert second.totals.activity_count == 1
    end

    test "aggregates only the sport types in the selected group" do
      # Cycling leaderboard should only include the Ride, not the runs
      {:ok, %{entries: entries}} = Leaderboards.get_team_leaderboard(:cycling_outdoor)

      assert length(entries) == 1
      [entry] = entries
      assert entry.team.name == "Team Alpha"
      assert entry.totals.distance_m == 50_000
    end

    test "excludes teamless users" do
      {:ok, %{entries: entries}} = Leaderboards.get_team_leaderboard(:running_outdoor)

      team_names = Enum.map(entries, & &1.team.name)
      refute "No Team" in team_names
    end

    test "filters by challenge_id when provided" do
      challenge =
        Repo.insert!(%SummerChallenge.Model.Challenge{
          name: "Team Challenge",
          start_date: ~U[2024-06-01 00:00:00Z],
          end_date: ~U[2024-08-31 23:59:59Z],
          allowed_sport_types: ["Run", "TrailRun"],
          status: "active"
        })

      # Tag only Team Alpha's first run with the challenge
      Repo.get_by!(Activity, strava_id: 201)
      |> Ecto.Changeset.change(%{challenge_id: challenge.id})
      |> Repo.update!()

      {:ok, %{entries: entries}} =
        Leaderboards.get_team_leaderboard(:running_outdoor, challenge_id: challenge.id)

      assert length(entries) == 1
      assert hd(entries).team.name == "Team Alpha"
      assert hd(entries).totals.distance_m == 10_000
    end

    test "respects excluded activities" do
      Repo.get_by!(Activity, strava_id: 203)
      |> Ecto.Changeset.change(%{excluded: true})
      |> Repo.update!()

      {:ok, %{entries: entries}} = Leaderboards.get_team_leaderboard(:running_outdoor)

      # Team Beta now has no included activities — should not appear
      team_names = Enum.map(entries, & &1.team.name)
      refute "Team Beta" in team_names
      assert length(entries) == 1
    end

    test "returns empty list for sport group with no team activities" do
      {:ok, %{entries: entries}} = Leaderboards.get_team_leaderboard(:running_virtual)
      assert entries == []
    end

    test "returns error for invalid sport group" do
      assert {:error, :invalid_sport_group} = Leaderboards.get_team_leaderboard(:invalid)
    end
  end
end
