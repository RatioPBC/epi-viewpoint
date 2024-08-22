import Config

config :epiviewpoint,
  application_version_sha: System.cmd("git", ["rev-parse", "HEAD"]) |> elem(0) |> String.trim(),
  seeds_enabled?: true

# Configure your database
repo_opts =
  if socket_dir = System.get_env("PGDATA"),
    do: [socket_dir: socket_dir],
    else: [username: "postgres", password: "postgres"]

config :epiviewpoint, EpiViewpoint.Repo, [database: "epiviewpoint_dev", show_sensitive_data_on_connection_error: true, pool_size: 10] ++ repo_opts

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :epiviewpoint, EpiViewpointWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    sass: {
      DartSass,
      :install_and_run,
      [:default, ~w(--embed-source-map --source-map-urls=absolute --watch)]
    }
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
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

# Watch static and templates for browser reloading.
config :epiviewpoint, EpiViewpointWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/epiviewpoint_web/(live|views)/.*(ex|heex)$",
      ~r"lib/epiviewpoint_web/templates/.*(eex|heex)$"
    ]
  ]

config :epiviewpoint, mfa_issuer: System.fetch_env!("CANONICAL_HOST")

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n", level: :warning

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :mix_test_watch, clear: true, extra_extensions: ~w(.slive)
