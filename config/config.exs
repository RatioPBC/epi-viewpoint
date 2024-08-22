# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
config :tzdata, :autoupdate, :disabled

config :epiviewpoint,
  clock: DateTime,
  ecto_repos: [EpiViewpoint.Repo],
  health_check: EpiViewpoint.HealthCheck,
  initial_user_email: System.get_env("INITIAL_USER_EMAIL"),
  phi_logger: EpiViewpoint.AuditLog.PhiLogger,
  seeds_enabled?: false,
  unpersisted_admin_id: "00000000-0000-0000-0000-000000000000"

# Configures the endpoint
config :epiviewpoint, EpiViewpointWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: EpiViewpointWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: EpiViewpoint.PubSub,
  live_view: [signing_salt: System.get_env("LIVE_VIEW_SIGNING_SALT")]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.18.6",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :dart_sass,
  version: "1.77.8",
  default: [
    args: ~w(css/app.sass ../priv/static/assets/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
