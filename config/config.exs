# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
config :tzdata, :autoupdate, :disabled

config :epicenter,
  clock: DateTime,
  ecto_repos: [Epicenter.Repo],
  health_check: Epicenter.HealthCheck,
  initial_user_email: System.get_env("INITIAL_USER_EMAIL"),
  phi_logger: Epicenter.AuditLog.PhiLogger,
  seeds_enabled?: false,
  unpersisted_admin_id: "00000000-0000-0000-0000-000000000000"

# Configures the endpoint
config :epicenter, EpicenterWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: EpicenterWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Epicenter.PubSub,
  live_view: [signing_salt: System.get_env("LIVE_VIEW_SIGNING_SALT")]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
