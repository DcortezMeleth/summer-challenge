defmodule SummerChallenge.OAuth.Strava do
  @moduledoc """
  OAuth2 strategy for Strava authentication.

  Handles the complete OAuth2 flow with Strava, including authorization,
  token exchange, and profile fetching.
  """

  use OAuth2.Strategy

  @doc """
  Returns the authorize URL for Strava OAuth.
  """
  def client do
    OAuth2.Client.new([
      strategy: __MODULE__,
      client_id: Application.get_env(:summer_challenge, :strava_client_id),
      client_secret: Application.get_env(:summer_challenge, :strava_client_secret),
      redirect_uri: Application.get_env(:summer_challenge, :strava_redirect_uri) || "http://localhost:4000/auth/strava/callback",
      site: "https://www.strava.com",
      authorize_url: "/oauth/authorize",
      token_url: "/oauth/token"
    ])
    |> OAuth2.Client.put_serializer("application/json", Jason)
  end

  @doc """
  Returns the authorization URL with required scopes.
  """
  def authorize_url!(params \\ []) do
    client()
    |> OAuth2.Client.authorize_url!(Keyword.merge(params, scope: "read,read_all,profile:read_all"))
  end

  @doc """
  Exchanges authorization code for access token.
  """
  def get_token!(params \\ [], headers \\ []) do
    # Use custom implementation to ensure proper form-encoded request
    exchange_token(params[:code])
  end

  @doc """
  Custom token exchange implementation using Req to ensure form-encoded data.
  """
  def exchange_token(code) do
    client = client()

    url = "#{client.site}#{client.token_url}"

    body = %{
      client_id: client.client_id,
      client_secret: client.client_secret,
      code: code,
      grant_type: "authorization_code"
    }

    headers = [
      {"Accept", "application/json"},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    require Logger
    Logger.info("OAuth Debug - Manual token exchange to: #{url}")
    Logger.info("OAuth Debug - Request body: #{inspect(body)}")

    case Req.post(url, form: body, headers: headers) do
      {:ok, %Req.Response{status: 200, body: token_data}} ->
        # Convert response to OAuth2.AccessToken struct
        OAuth2.AccessToken.new(token_data)

      {:ok, %Req.Response{body: error_data}} ->
        raise OAuth2.Error, reason: "Server responded with error: #{inspect(error_data)}"

      {:error, error} ->
        raise OAuth2.Error, reason: "Request failed: #{inspect(error)}"
    end
  end

  @doc """
  Fetches athlete profile from Strava API.
  """
  def get_athlete(token) do
    client = client()
    url = "#{client.site}/api/v3/athlete"

    headers = [
      {"Authorization", "Bearer #{token.access_token}"},
      {"Accept", "application/json"}
    ]

    case Req.get(url, headers: headers) do
      {:ok, %Req.Response{status: 200, body: athlete}} ->
        {:ok, athlete}

      {:ok, %Req.Response{body: %{"message" => message}}} ->
        {:error, message}

      {:error, error} ->
        {:error, error}
    end
  end

  # OAuth2.Strategy callbacks

  @impl OAuth2.Strategy
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  @impl OAuth2.Strategy
  def get_token(client, params, headers) do
    require Logger
    Logger.info("OAuth Debug - Token request params: #{inspect(params)}")
    Logger.info("OAuth Debug - Client config: #{inspect(%{client_id: client.client_id, client_secret: String.length(client.client_secret), redirect_uri: client.redirect_uri})}")

    # Strava expects form-encoded data for token exchange, not JSON
    # Remove JSON serializer and use form-encoded instead
    client = %{client | serializers: %{}}

    client
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
