import Config

# Do not print debug messages in production
config :logger, level: :info

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Req

# Disable Swoosh Local Memory Storage
# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
config :swoosh, local: false
