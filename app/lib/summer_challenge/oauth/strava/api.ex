defmodule SummerChallenge.OAuth.Strava.API do
  @moduledoc "Behaviour for mocking Strava API calls in tests."

  @callback authorize_url!(keyword()) :: String.t()
  @callback get_token!(keyword()) :: {OAuth2.AccessToken.t(), map() | nil}
  @callback get_athlete(OAuth2.AccessToken.t()) :: {:ok, map()} | {:error, term()}
  @callback list_activities(OAuth2.AccessToken.t(), map()) :: {:ok, [map()]} | {:error, term()}
  @callback refresh_token(String.t()) :: {:ok, map()} | {:error, term()}
end
