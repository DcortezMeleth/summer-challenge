import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :summer_challenge, SummerChallenge.Repo,
  username: "bsadel",
  password: "",
  hostname: "localhost",
  database: "summer_challenge_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :summer_challenge, SummerChallengeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "F2oFDcpi61xlLy5h5fr4qQ7N1aprmXpKO4OMN+jvtwZEmCQ1bWMAyTwOReD9iJ+m",
  server: false

# In test we don't send emails
config :summer_challenge, SummerChallenge.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Use mock for Strava client in tests
config :summer_challenge, :strava_client, SummerChallenge.OAuth.StravaMock

# Disable Oban job processing in tests
config :summer_challenge, Oban, testing: :manual

config :phoenix_live_view,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true
