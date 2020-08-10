use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :epicenter, Epicenter.Repo,
  database: "epicenter_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  password: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox,
  username: "postgres"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :epicenter, EpicenterWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
