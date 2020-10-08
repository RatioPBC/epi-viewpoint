# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :epicenter,
  ecto_repos: [Epicenter.Repo],
  seeds_enabled?: false

# Configures the endpoint
config :epicenter, EpicenterWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ZUHdh7oLc6zGSaqOFlF6PMIAw//3cB916WPDO5Ny10ugUPWVStG2J18BTBs+9kFc",
  render_errors: [view: EpicenterWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Epicenter.PubSub,
  live_view: [signing_salt: "KRXie/vG"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# slime
config :phoenix_slime, :use_slim_extension, true

config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine,
  slimleex: PhoenixSlime.LiveViewEngine

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
