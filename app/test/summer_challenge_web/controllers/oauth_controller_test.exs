defmodule SummerChallengeWeb.OAuthControllerTest do
  use SummerChallengeWeb.ConnCase
  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "GET /auth/strava/callback" do
    test "redirects to onboarding for new user", %{conn: conn} do
      code = "valid_code"

      token = %OAuth2.AccessToken{
        access_token: "access_token",
        refresh_token: "refresh_token",
        expires_at: DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()
      }

      athlete = %{"id" => 111, "firstname" => "New", "lastname" => "User"}

      SummerChallenge.OAuth.StravaMock
      |> expect(:get_token!, fn [code: ^code] -> token end)
      |> expect(:get_athlete, fn ^token -> {:ok, athlete} end)

      conn = get(conn, ~p"/auth/strava/callback", code: code, state: "ignored_in_mvp")

      assert redirected_to(conn) == ~p"/onboarding"
      assert get_session(conn, :user_id)
    end

    test "redirects to dashboard for existing onboarded user", %{conn: conn} do
      # Setup existing user
      athlete = %{"id" => 222, "firstname" => "Old", "lastname" => "User"}
      {:ok, user} = SummerChallenge.Accounts.find_or_create_user_from_strava(athlete)
      SummerChallenge.Accounts.complete_onboarding(user.id, "Old User")

      code = "valid_code"

      token = %OAuth2.AccessToken{
        access_token: "access_token",
        refresh_token: "refresh_token",
        expires_at: DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()
      }

      SummerChallenge.OAuth.StravaMock
      |> expect(:get_token!, fn [code: ^code] -> token end)
      |> expect(:get_athlete, fn ^token -> {:ok, athlete} end)

      conn = get(conn, ~p"/auth/strava/callback", code: code, state: "ignored_in_mvp")

      assert redirected_to(conn) == ~p"/leaderboard/running"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Successfully signed in"
    end

    test "handles strava errors gracefully", %{conn: conn} do
      code = "invalid_code"

      SummerChallenge.OAuth.StravaMock
      |> expect(:get_token!, fn [code: ^code] -> raise OAuth2.Error, reason: "Invalid code" end)

      conn = get(conn, ~p"/auth/strava/callback", code: code, state: "ignored_in_mvp")

      assert redirected_to(conn) == ~p"/leaderboard/running"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Authentication failed"
    end
  end
end
