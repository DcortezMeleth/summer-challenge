defmodule SummerChallengeWeb.LeaderboardLiveTest do
  use SummerChallengeWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Leaderboard UI authentication" do
    test "shows sign in button for guests", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/leaderboard/running_outdoor")

      assert html =~ "Connect with Strava"
      refute html =~ "Sign out"
      refute html =~ "Ready to compete"
    end

    test "shows welcome message and sign out button for authenticated users", %{conn: conn} do
      user = %SummerChallenge.Model.User{
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
      _user = SummerChallenge.Repo.insert!(user)

      {:ok, _view, html} = live(conn, ~p"/leaderboard/running_outdoor")

      assert html =~ "Test Athlete"
      assert html =~ "Ready to compete"
      assert html =~ "Sign out"
      assert html =~ "href=\"/auth/logout\""
      assert html =~ "data-method=\"delete\""
      refute html =~ "Connect with Strava"
    end
  end
end
