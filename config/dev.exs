import Config

# Configure your database
config :overflow, Overflow.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "overflow_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :overflow, OverflowWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base:
    System.get_env("SECRET_KEY_BASE") ||
      "5Pq38oeEkIH8of7DL0o7DDrv4XJpISbWI64/OreuLq4qAPaJN2mKIzgOkEBKUwct",
  watchers: []

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Enable dev routes for dashboard and mailbox
config :overflow, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

ranking_provider =
  case System.get_env("RANKING_PROVIDER", "local") do
    "local" -> :local
    "gemini" -> :gemini
    _ -> :local
  end

config :overflow, :ranking_provider, ranking_provider

config :overflow,
       :ml_ranking_url,
       System.get_env("ML_RANKING_URL", "http://localhost:11434/v1/chat/completions")

config :overflow, :gemini,
  api_key: System.get_env("GEMINI_API_KEY", ""),
  api_url: System.get_env("GEMINI_API_URL", "")
