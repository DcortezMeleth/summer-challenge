defmodule SummerChallengeWeb.Router do
  use SummerChallengeWeb, :router

  import Phoenix.LiveView.Router

  alias SummerChallengeWeb.Hooks.Auth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes - no authentication required
  scope "/", SummerChallengeWeb do
    pipe_through :browser

    get "/", PageController, :home

    # OAuth routes
    get "/auth/strava", OAuthController, :request
    get "/auth/strava/callback", OAuthController, :callback
    delete "/auth/logout", OAuthController, :delete

    live_session :public, on_mount: {Auth, :optional} do
      live "/leaderboard/:sport", LeaderboardLive, :index
    end

    live_session :authenticated, on_mount: {Auth, :require_authenticated_user} do
      live "/onboarding", OnboardingLive, :index
      # TODO: Add other authenticated routes here (my/activities, teams, admin, etc.)
    end
  end

  scope "/api", SummerChallengeWeb do
    pipe_through :api
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:summer_challenge, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: SummerChallengeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
