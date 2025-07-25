# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :overflow,
  ecto_repos: [Overflow.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true],
  token_salt: System.get_env("TOKEN_SALT", "user_auth_default_salt_change_in_production"),
  api_timeout: 30_000

# Configures the endpoint
config :overflow, OverflowWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: OverflowWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Overflow.PubSub,
  live_view: [signing_salt: "xhjxaYm6"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :overflow, Overflow.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# CORS configuration
config :cors_plug,
  origin: ["*"],
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  headers: ["authorization", "content-type", "x-requested-with"],
  max_age: 86400

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
