defmodule SummerChallenge.MilestonesTest do
  use SummerChallenge.DataCase

  alias SummerChallenge.{Milestones, Challenges, Repo}
  alias SummerChallenge.Model.{User, Activity}

  describe "get_milestone_achievers/1" do
    setup do
      {:ok, challenge} = Challenges.create_challenge(%{
        name: "Milestone Test Challenge",
        start_date: DateTime.add(DateTime.utc_now(), -30, :day),
        end_date: DateTime.add(DateTime.utc_now(), 30, :day),
        allowed_sport_types: ["Run", "Ride"],
        status: "active"
      })

      %{challenge: challenge}
    end

    test "returns users who reached 40-hour milestone", %{challenge: challenge} do
      # User with exactly 40 hours
      user1 = Repo.insert!(%User{
        display_name: "Achiever One",
        strava_athlete_id: 111,
        joined_at: DateTime.utc_now()
      })

      Repo.insert!(%Activity{
        user_id: user1.id,
        challenge_id: challenge.id,
        strava_id: 1,
        sport_type: "Run",
        start_at: DateTime.add(DateTime.utc_now(), -5, :day),
        distance_m: 50000,
        moving_time_s: 40 * 60 * 60,  # Exactly 40 hours
        elev_gain_m: 500,
        excluded: false
      })

      # User with more than 40 hours
      user2 = Repo.insert!(%User{
        display_name: "Achiever Two",
        strava_athlete_id: 222,
        joined_at: DateTime.utc_now()
      })

      Repo.insert!(%Activity{
        user_id: user2.id,
        challenge_id: challenge.id,
        strava_id: 2,
        sport_type: "Ride",
        start_at: DateTime.add(DateTime.utc_now(), -3, :day),
        distance_m: 100000,
        moving_time_s: 50 * 60 * 60,  # 50 hours
        elev_gain_m: 1000,
        excluded: false
      })

      {:ok, %{achievers: achievers}} = Milestones.get_milestone_achievers(challenge_id: challenge.id)

      assert length(achievers) == 2
      
      # Should be sorted alphabetically by display name
      assert Enum.at(achievers, 0).user.display_name == "Achiever One"
      assert Enum.at(achievers, 0).total_moving_time_s == 40 * 60 * 60
      
      assert Enum.at(achievers, 1).user.display_name == "Achiever Two"
      assert Enum.at(achievers, 1).total_moving_time_s == 50 * 60 * 60
    end

    test "excludes users below 40-hour threshold", %{challenge: challenge} do
      # User with 39 hours (just under)
      user = Repo.insert!(%User{
        display_name: "Almost There",
        strava_athlete_id: 333,
        joined_at: DateTime.utc_now()
      })

      Repo.insert!(%Activity{
        user_id: user.id,
        challenge_id: challenge.id,
        strava_id: 1,
        sport_type: "Run",
        start_at: DateTime.add(DateTime.utc_now(), -5, :day),
        distance_m: 40000,
        moving_time_s: 39 * 60 * 60,  # 39 hours
        elev_gain_m: 400,
        excluded: false
      })

      {:ok, %{achievers: achievers}} = Milestones.get_milestone_achievers(challenge_id: challenge.id)

      assert achievers == []
    end

    test "aggregates multiple activities to reach threshold", %{challenge: challenge} do
      user = Repo.insert!(%User{
        display_name: "Multi Activity",
        strava_athlete_id: 444,
        joined_at: DateTime.utc_now()
      })

      # Create multiple activities that together exceed 40 hours
      Repo.insert!(%Activity{
        user_id: user.id,
        challenge_id: challenge.id,
        strava_id: 1,
        sport_type: "Run",
        start_at: DateTime.add(DateTime.utc_now(), -10, :day),
        distance_m: 20000,
        moving_time_s: 15 * 60 * 60,  # 15 hours
        elev_gain_m: 200,
        excluded: false
      })

      Repo.insert!(%Activity{
        user_id: user.id,
        challenge_id: challenge.id,
        strava_id: 2,
        sport_type: "Ride",
        start_at: DateTime.add(DateTime.utc_now(), -5, :day),
        distance_m: 60000,
        moving_time_s: 20 * 60 * 60,  # 20 hours
        elev_gain_m: 500,
        excluded: false
      })

      Repo.insert!(%Activity{
        user_id: user.id,
        challenge_id: challenge.id,
        strava_id: 3,
        sport_type: "Run",
        start_at: DateTime.add(DateTime.utc_now(), -2, :day),
        distance_m: 10000,
        moving_time_s: 6 * 60 * 60,  # 6 hours
        elev_gain_m: 100,
        excluded: false
      })

      {:ok, %{achievers: achievers}} = Milestones.get_milestone_achievers(challenge_id: challenge.id)

      assert length(achievers) == 1
      assert hd(achievers).user.display_name == "Multi Activity"
      assert hd(achievers).total_moving_time_s == 41 * 60 * 60  # 41 hours total
    end

    test "excludes activities marked as excluded", %{challenge: challenge} do
      user = Repo.insert!(%User{
        display_name: "Excluded Activities",
        strava_athlete_id: 555,
        joined_at: DateTime.utc_now()
      })

      # Included activity - 30 hours
      Repo.insert!(%Activity{
        user_id: user.id,
        challenge_id: challenge.id,
        strava_id: 1,
        sport_type: "Run",
        start_at: DateTime.add(DateTime.utc_now(), -10, :day),
        distance_m: 30000,
        moving_time_s: 30 * 60 * 60,
        elev_gain_m: 300,
        excluded: false
      })

      # Excluded activity - 15 hours (would put them over 40)
      Repo.insert!(%Activity{
        user_id: user.id,
        challenge_id: challenge.id,
        strava_id: 2,
        sport_type: "Run",
        start_at: DateTime.add(DateTime.utc_now(), -5, :day),
        distance_m: 15000,
        moving_time_s: 15 * 60 * 60,
        elev_gain_m: 150,
        excluded: true  # Excluded
      })

      {:ok, %{achievers: achievers}} = Milestones.get_milestone_achievers(challenge_id: challenge.id)

      # Should not appear since only 30 hours are counted
      assert achievers == []
    end

    test "only counts activities from the specified challenge", %{challenge: challenge} do
      # Create another challenge
      {:ok, other_challenge} = Challenges.create_challenge(%{
        name: "Other Challenge",
        start_date: DateTime.add(DateTime.utc_now(), -60, :day),
        end_date: DateTime.add(DateTime.utc_now(), -31, :day),
        allowed_sport_types: ["Run"],
        status: "archived"
      })

      user = Repo.insert!(%User{
        display_name: "Two Challenges",
        strava_athlete_id: 666,
        joined_at: DateTime.utc_now()
      })

      # Activity in the specified challenge - 30 hours
      Repo.insert!(%Activity{
        user_id: user.id,
        challenge_id: challenge.id,
        strava_id: 1,
        sport_type: "Run",
        start_at: DateTime.add(DateTime.utc_now(), -5, :day),
        distance_m: 30000,
        moving_time_s: 30 * 60 * 60,
        elev_gain_m: 300,
        excluded: false
      })

      # Activity in another challenge - 20 hours (would reach 50 total)
      Repo.insert!(%Activity{
        user_id: user.id,
        challenge_id: other_challenge.id,
        strava_id: 2,
        sport_type: "Run",
        start_at: DateTime.add(DateTime.utc_now(), -45, :day),
        distance_m: 20000,
        moving_time_s: 20 * 60 * 60,
        elev_gain_m: 200,
        excluded: false
      })

      {:ok, %{achievers: achievers}} = Milestones.get_milestone_achievers(challenge_id: challenge.id)

      # Should not appear since only 30 hours in this challenge
      assert achievers == []
    end

    test "includes team name in results", %{challenge: challenge} do
      # Create a team owner first
      owner = Repo.insert!(%User{
        display_name: "Team Owner",
        strava_athlete_id: 888,
        joined_at: DateTime.utc_now()
      })

      # Create a team
      team = Repo.insert!(%SummerChallenge.Model.Team{
        name: "Fast Runners",
        owner_user_id: owner.id
      })

      user = Repo.insert!(%User{
        display_name: "Team Member",
        strava_athlete_id: 777,
        team_id: team.id,
        joined_at: DateTime.utc_now()
      })

      Repo.insert!(%Activity{
        user_id: user.id,
        challenge_id: challenge.id,
        strava_id: 1,
        sport_type: "Run",
        start_at: DateTime.add(DateTime.utc_now(), -5, :day),
        distance_m: 50000,
        moving_time_s: 45 * 60 * 60,
        elev_gain_m: 500,
        excluded: false
      })

      {:ok, %{achievers: achievers}} = Milestones.get_milestone_achievers(challenge_id: challenge.id)

      assert length(achievers) == 1
      assert hd(achievers).user.team_name == "Fast Runners"
    end

    test "returns error when challenge_id is not provided" do
      assert {:error, :challenge_id_required} = Milestones.get_milestone_achievers()
    end
  end

  describe "milestone_threshold_seconds/0" do
    test "returns 40 hours in seconds" do
      assert Milestones.milestone_threshold_seconds() == 144_000
    end
  end

  describe "milestone_threshold_hours/0" do
    test "returns 40 hours" do
      assert Milestones.milestone_threshold_hours() == 40
    end
  end
end
