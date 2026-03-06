defmodule SummerChallengeWeb.LeaderboardLiveTest do
  use SummerChallengeWeb.ConnCase

  import Phoenix.LiveViewTest

  alias SummerChallenge.Model.Activity
  alias SummerChallenge.Model.Challenge
  alias SummerChallenge.Model.Team
  alias SummerChallenge.Model.User
  alias SummerChallenge.Repo

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Creates a challenge that is currently active (dates cover today, 2026).
  defp insert_challenge(attrs \\ %{}) do
    Repo.insert!(%Challenge{
      name: Map.get(attrs, :name, "Test Challenge"),
      start_date: Map.get(attrs, :start_date, ~U[2026-01-01 00:00:00Z]),
      end_date: Map.get(attrs, :end_date, ~U[2026-12-31 23:59:59Z]),
      allowed_sport_types: Map.get(attrs, :allowed_sport_types, ["Run", "TrailRun", "Ride"]),
      status: Map.get(attrs, :status, "active")
    })
  end

  defp insert_user(strava_id, display_name, team_id \\ nil) do
    Repo.insert!(%User{
      strava_athlete_id: strava_id,
      display_name: display_name,
      team_id: team_id
    })
  end

  defp insert_run(user_id, strava_id, distance_m, challenge_id \\ nil) do
    Repo.insert!(%Activity{
      user_id: user_id,
      strava_id: strava_id,
      sport_type: "Run",
      start_at: ~U[2024-06-01 10:00:00.000000Z],
      distance_m: distance_m,
      moving_time_s: 3600,
      elev_gain_m: 100,
      challenge_id: challenge_id
    })
  end

  describe "Leaderboard UI authentication" do
    test "shows sign in button for guests", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/leaderboard/running_outdoor")

      assert html =~ "Connect with Strava"
      refute html =~ "Sign out"
      refute html =~ "Ready to compete"
    end

    test "shows welcome message and sign out button for authenticated users", %{conn: conn} do
      user = %User{
        id: Ecto.UUID.generate(),
        display_name: "Test Athlete",
        joined_at: DateTime.utc_now()
      }

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> assign(:current_user, user)
        |> assign(:current_scope, %{authenticated?: true, user_id: user.id})

      # Mock Accounts.get_user to return our test user
      # We don't need Mox here if we just want to test rendering with session,
      # but the Auth hook will call Accounts.get_user.
      # Let's ensure the user exists in the DB for the hook to find it.
      _user = Repo.insert!(user)

      {:ok, _view, html} = live(conn, ~p"/leaderboard/running_outdoor")

      assert html =~ "Test Athlete"
      assert html =~ "Ready to compete"
      assert html =~ "Sign out"
      assert html =~ "href=\"/auth/logout\""
      assert html =~ "data-method=\"delete\""
      refute html =~ "Connect with Strava"
    end
  end

  describe "Team standings section" do
    test "does not render team standings when no teams have activities", %{conn: conn} do
      # A challenge must exist for the view to show leaderboard data at all
      insert_challenge()

      {:ok, _view, html} = live(conn, ~p"/leaderboard/running_outdoor")

      refute html =~ "Team Standings"
    end

    test "renders team standings when teams have activities for the sport", %{conn: conn} do
      challenge = insert_challenge()

      team_a = Repo.insert!(%Team{name: "Swift Pacers", owner_user_id: nil})
      team_b = Repo.insert!(%Team{name: "Iron Cyclists", owner_user_id: nil})

      user_a1 = insert_user(601, "Alpha One", team_a.id)
      user_a2 = insert_user(602, "Alpha Two", team_a.id)
      user_b1 = insert_user(603, "Beta One", team_b.id)

      insert_run(user_a1.id, 301, 10_000, challenge.id)
      insert_run(user_a2.id, 302, 8_000, challenge.id)
      insert_run(user_b1.id, 303, 5_000, challenge.id)

      {:ok, _view, html} = live(conn, ~p"/leaderboard/running_outdoor")

      assert html =~ "Team Standings"
      assert html =~ "Swift Pacers"
      assert html =~ "Iron Cyclists"
    end

    test "team standings are ordered by total distance descending", %{conn: conn} do
      challenge = insert_challenge()

      team_a = Repo.insert!(%Team{name: "Slow Team", owner_user_id: nil})
      team_b = Repo.insert!(%Team{name: "Fast Team", owner_user_id: nil})

      user_a = insert_user(611, "Slow Runner", team_a.id)
      user_b = insert_user(612, "Fast Runner", team_b.id)

      insert_run(user_a.id, 311, 3_000, challenge.id)
      insert_run(user_b.id, 312, 15_000, challenge.id)

      {:ok, _view, html} = live(conn, ~p"/leaderboard/running_outdoor")

      fast_pos = html |> :binary.match("Fast Team") |> elem(0)
      slow_pos = html |> :binary.match("Slow Team") |> elem(0)

      assert fast_pos < slow_pos
    end

    test "team standings section is absent for sport with no team activity", %{conn: conn} do
      challenge = insert_challenge()

      team = Repo.insert!(%Team{name: "Runners Only", owner_user_id: nil})
      user = insert_user(621, "Runner Z", team.id)
      # Running activity tagged to challenge — but we navigate to cycling, so no team standings
      insert_run(user.id, 321, 10_000, challenge.id)

      {:ok, _view, html} = live(conn, ~p"/leaderboard/cycling_outdoor")

      refute html =~ "Team Standings"
    end

    test "team standings respect challenge_id filter", %{conn: conn} do
      challenge = insert_challenge()
      other_challenge = insert_challenge(%{name: "Other Challenge"})

      team = Repo.insert!(%Team{name: "Challenge Team", owner_user_id: nil})
      user = insert_user(631, "Challenge Runner", team.id)

      # Activity tagged to challenge
      insert_run(user.id, 331, 10_000, challenge.id)
      # Activity tagged to a different challenge — must not be counted
      insert_run(user.id, 332, 50_000, other_challenge.id)

      {:ok, _view, html} = live(conn, ~p"/leaderboard/running_outdoor?challenge_id=#{challenge.id}")

      assert html =~ "Team Standings"
      assert html =~ "Challenge Team"
      # Only the 10 km run should count — check that 50 km distance is NOT shown
      refute html =~ "50.0"
    end
  end
end
