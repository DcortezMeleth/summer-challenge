defmodule SummerChallenge.OAuth.Strava do
  @moduledoc """
  OAuth2 strategy for Strava authentication.

  Handles the complete OAuth2 flow with Strava, including authorization,
  token exchange, and profile fetching.
  """

  @behaviour API

  use OAuth2.Strategy

  alias OAuth2.Strategy.AuthCode

  # Define logic for mocking
  defmodule API do
    @moduledoc false
    @callback authorize_url!(keyword()) :: String.t()
    @callback get_token!(keyword()) :: OAuth2.AccessToken.t()
    @callback get_athlete(OAuth2.AccessToken.t()) :: {:ok, map()} | {:error, term()}
    @callback list_activities(OAuth2.AccessToken.t(), map()) :: {:ok, [map()]} | {:error, term()}
    @callback refresh_token(String.t()) :: {:ok, map()} | {:error, term()}
  end

  @doc """
  Returns the authorize URL for Strava OAuth.
  """
  def client do
    [
      strategy: __MODULE__,
      client_id: Application.get_env(:summer_challenge, :strava_client_id),
      client_secret: Application.get_env(:summer_challenge, :strava_client_secret),
      redirect_uri:
        Application.get_env(:summer_challenge, :strava_redirect_uri) ||
          "http://localhost:4000/auth/strava/callback",
      site: "https://www.strava.com",
      authorize_url: "/oauth/authorize",
      token_url: "/oauth/token"
    ]
    |> OAuth2.Client.new()
    |> OAuth2.Client.put_serializer("application/json", Jason)
  end

  @doc """
  Returns the authorization URL with required scopes.
  """
  @impl true
  def authorize_url!(params \\ []) do
    OAuth2.Client.authorize_url!(
      client(),
      Keyword.put(params, :scope, "read,read_all,profile:read_all,activity:read,activity:read_all")
    )
  end

  @doc """
  Exchanges authorization code for access token.
  """
  @impl true
  def get_token!(params \\ []) do
    # Use custom implementation to ensure proper form-encoded request
    exchange_token(params[:code])
  end

  @doc """
  Custom token exchange implementation using Req to ensure form-encoded data.
  """
  def exchange_token(code) do
    require Logger

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
  @impl true
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

  @doc """
  Fetches athlete activities from Strava API.

  Parameters:
  - `token`: OAuth2 access token
  - `params`: Query parameters (e.g., `after`, `before`, `page`, `per_page`)
  """
  @impl true
  def list_activities(token, params \\ %{}) do
    client = client()
    url = "#{client.site}/api/v3/athlete/activities"

    headers = [
      {"Authorization", "Bearer #{token.access_token}"},
      {"Accept", "application/json"}
    ]

    case Req.get(url, headers: headers, params: params) do
      {:ok, %Req.Response{status: 200, body: activities}} ->
        {:ok, activities}

      {:ok, %Req.Response{body: %{"message" => message}}} ->
        {:error, message}

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def refresh_token(refresh_token) do
    client = client()
    url = "#{client.site}#{client.token_url}"

    body = %{
      client_id: client.client_id,
      client_secret: client.client_secret,
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    }

    headers = [
      {"Accept", "application/json"},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    case Req.post(url, form: body, headers: headers) do
      {:ok, %Req.Response{status: 200, body: token_data}} ->
        {:ok, token_data}

      {:ok, %Req.Response{body: error_data}} ->
        {:error, error_data}

      {:error, error} ->
        {:error, error}
    end
  end

  # OAuth2.Strategy callbacks

  @impl OAuth2.Strategy
  def authorize_url(client, params) do
    AuthCode.authorize_url(client, params)
  end

  @impl OAuth2.Strategy
  def get_token(client, params, headers) do
    require Logger

    Logger.info("OAuth Debug - Token request params: #{inspect(params)}")

    Logger.info(
      "OAuth Debug - Client config: #{inspect(%{client_id: client.client_id, client_secret: String.length(client.client_secret), redirect_uri: client.redirect_uri})}"
    )

    # Strava expects form-encoded data for token exchange, not JSON
    # Remove JSON serializer and use form-encoded instead
    client = %{client | serializers: %{}}

    client
    |> put_header("Accept", "application/json")
    |> AuthCode.get_token(params, headers)
  end
end
