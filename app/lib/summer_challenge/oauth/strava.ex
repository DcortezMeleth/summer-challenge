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
      redirect_uri: "http://localhost:4000/auth/strava/callback",
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
    client()
    |> OAuth2.Client.get_token!(Keyword.merge(params, headers: headers))
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
    client
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
