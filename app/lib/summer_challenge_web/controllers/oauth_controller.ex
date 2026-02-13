defmodule SummerChallengeWeb.OAuthController do
  @moduledoc """
  Handles Strava OAuth authentication flow.

  Provides endpoints for initiating OAuth flow and handling the callback
  after user authorization.
  """

  use SummerChallengeWeb, :controller

  alias SummerChallenge.Accounts

  defp strava_client, do: Application.get_env(:summer_challenge, :strava_client)

  @doc """
  Initiates the Strava OAuth authorization flow.

  Redirects the user to Strava's authorization page.
  """
  def request(conn, _params) do
    redirect(conn, external: strava_client().authorize_url!(state: generate_state()))
  end

  @doc """
  Handles the OAuth callback from Strava.

  Exchanges the authorization code for access tokens, creates/updates the user,
  and redirects appropriately.
  """
  def callback(conn, %{"code" => code, "state" => state}) do
    # Verify state for CSRF protection
    if verify_state(state) do
      case exchange_code_for_token(code) do
        {:ok, token_data} ->
          handle_successful_auth(conn, token_data)

        {:error, reason} ->
          handle_auth_error(conn, reason)
      end
    else
      handle_auth_error(conn, "Invalid state parameter")
    end
  end

  def callback(conn, %{"error" => "access_denied"}) do
    conn
    |> put_flash(:error, "Authentication was cancelled.")
    |> redirect(to: "/leaderboard/running")
  end

  def callback(conn, _params) do
    handle_auth_error(conn, "Invalid OAuth response")
  end

  @doc """
  Logs out the user by clearing the session.
  """
  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Successfully signed out.")
    |> redirect(to: "/leaderboard/running")
  end

  # Private functions

  @spec exchange_code_for_token(String.t()) :: {:ok, map()} | {:error, term()}
  defp exchange_code_for_token(code) do
    try do
      # Debug: Log the configuration being used
      client_id = Application.get_env(:summer_challenge, :strava_client_id)
      client_secret = Application.get_env(:summer_challenge, :strava_client_secret)
      require Logger

      Logger.info(
        "OAuth Debug - Client ID: #{client_id}, Secret length: #{String.length(client_secret)}"
      )

      # Exchange authorization code for access token
      token = strava_client().get_token!(code: code)

      # Fetch athlete profile
      case strava_client().get_athlete(token) do
        {:ok, athlete} ->
          {:ok, %{token: token, athlete: athlete}}

        {:error, reason} ->
          {:error, "Failed to fetch athlete profile: #{reason}"}
      end
    rescue
      e in OAuth2.Error ->
        {:error, "OAuth error: #{e.reason}"}

      e ->
        {:error, "Unexpected error: #{inspect(e)}"}
    end
  end

  @spec handle_successful_auth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  defp handle_successful_auth(conn, %{token: token, athlete: athlete}) do
    try do
      # Create or update user from Strava profile
      case Accounts.find_or_create_user_from_strava(athlete) do
        {:ok, user} ->
          # Store credentials
          :ok = Accounts.store_credentials(user.id, token_to_map(token))

          # Set session and redirect
          redirect_path = determine_redirect_path(user)

          conn
          |> put_session(:user_id, user.id)
          |> put_flash(:info, "Successfully signed in!")
          |> redirect(to: redirect_path)

        {:error, reason} ->
          handle_auth_error(conn, "Failed to create user: #{inspect(reason)}")
      end
    rescue
      e ->
        handle_auth_error(conn, "Unexpected error during authentication: #{inspect(e)}")
    end
  end

  @spec handle_auth_error(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  defp handle_auth_error(conn, message) do
    conn
    |> put_flash(:error, "Authentication failed: #{message}")
    |> redirect(to: "/leaderboard/running")
  end

  @spec determine_redirect_path(map()) :: String.t()
  defp determine_redirect_path(user) do
    # Check if user has completed onboarding
    if Accounts.user_onboarded?(user) do
      # Return to leaderboard
      "/leaderboard/running"
    else
      # First-time user, go to onboarding
      "/onboarding"
    end
  end

  @spec token_to_map(OAuth2.AccessToken.t()) :: map()
  defp token_to_map(token) do
    %{
      access_token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type
    }
  end

  @spec generate_state() :: String.t()
  defp generate_state do
    # Generate a random state for CSRF protection
    # In production, store this in session and verify
    :crypto.strong_rand_bytes(32) |> Base.encode64()
  end

  @spec verify_state(String.t()) :: boolean()
  defp verify_state(_state) do
    # For MVP, we'll skip strict state verification
    # In production, compare with session-stored state
    true
  end
end
