defmodule SummerChallengeWeb.OnboardingLiveTest do
  use SummerChallengeWeb.ConnCase
  import Phoenix.LiveViewTest

  alias SummerChallenge.Accounts

  defp create_user(_) do
    athlete = %{"id" => 123, "firstname" => "Test", "lastname" => "User"}
    {:ok, user} = Accounts.find_or_create_user_from_strava(athlete)
    %{user: user}
  end

  describe "Onboarding LiveView" do
    setup [:create_user]

    test "mounts successfully for authenticated user", %{conn: conn, user: user} do
      {:ok, _view, html} =
        conn
        |> init_test_session(%{user_id: user.id})
        |> live(~p"/onboarding")

      assert html =~ "You are joining the challenge"
      assert html =~ "Enter your display name"
    end

    test "redirects to leaderboard if already onboarded", %{conn: conn, user: user} do
      {:ok, user} = Accounts.complete_onboarding(user.id, "Onboarded User")

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> get(~p"/onboarding")

      assert redirected_to(conn) == ~p"/leaderboard/running"
    end

    test "validates display name", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> init_test_session(%{user_id: user.id})
        |> live(~p"/onboarding")

      view
      |> form("#onboarding-form", onboarding: %{display_name: ""})
      |> render_change()

      assert render(view) =~ "Display name cannot be blank"
    end

    test "completes onboarding successfully", %{conn: conn, user: user} do
      {:ok, view, _html} =
        conn
        |> init_test_session(%{user_id: user.id})
        |> live(~p"/onboarding")

      view
      |> form("#onboarding-form", onboarding: %{display_name: "New Name"})
      |> render_submit()

      assert_redirected(view, ~p"/leaderboard/running")

      # Verify user is updated
      updated_user = Accounts.get_user(user.id)
      assert updated_user.display_name == "New Name"
      assert updated_user.joined_at != nil
    end
  end
end
