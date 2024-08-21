import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
repo_opts =
  if socket_dir = System.get_env("PGDATA"),
    do: [socket_dir: socket_dir],
    else: [username: "postgres", password: "postgres", hostname: System.get_env("POSTGRES_HOST", "localhost")]

config :epiviewpoint,
       EpiViewpoint.Repo,
       [
         database: "epiviewpoint_test#{System.get_env("MIX_TEST_PARTITION")}",
         pool: Ecto.Adapters.SQL.Sandbox,
         pool_size: 16,
         queue_target: 300,
         queue_interval: 5000
       ] ++ repo_opts

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :epiviewpoint, EpiViewpointWeb.Endpoint,
  http: [port: 4002],
  server: false

config :epiviewpoint,
  application_version_sha: "test-version-sha",
  clock: FakeDateTime,
  health_check: EpiViewpoint.Test.HealthCheckMock,
  totp: EpiViewpoint.Test.TOTPMock,
  phi_logger: EpiViewpoint.Test.PhiLoggerMock

# Print only warnings and errors during test
config :logger, level: :warning, metadata: :all

config :phoenix_integration,
  endpoint: EpiViewpointWeb.Endpoint
