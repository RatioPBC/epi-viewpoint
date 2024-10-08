import Config

defmodule CFG do
  def application_port(), do: String.to_integer(System.get_env("PORT", "4000"))
  def canonical_host(), do: System.fetch_env!("CANONICAL_HOST")
  def live_view_signing_salt(), do: System.get_env("LIVE_VIEW_SIGNING_SALT")
  def secret_key_base(), do: System.fetch_env!("SECRET_KEY_BASE")

  def database_url() do
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """
  end

  def to_boolean("true"), do: true
  def to_boolean(_), do: false
end

config :epiviewpoint,
  application_version_sha: :code.priv_dir(:epiviewpoint) |> Path.join("static/version.txt") |> File.read!() |> String.trim(),
  mfa_issuer: CFG.canonical_host()

config :epiviewpoint, EpiViewpoint.Repo,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: CFG.to_boolean(System.get_env("DBSSL", "true")),
  url: CFG.database_url()

config :epiviewpoint, EpiViewpointWeb.Endpoint,
  http: [port: CFG.application_port()],
  live_view: [signing_salt: CFG.live_view_signing_salt()],
  secret_key_base: CFG.secret_key_base(),
  server: true,
  url: [
    host: CFG.canonical_host(),
    port: 443,
    scheme: "https"
  ]

config :logger_json, :google_error_reporter,
  service_context: [
    service: System.fetch_env!("ERROR_REPORTER_SERVICE_NAME"),
    version: :code.priv_dir(:epiviewpoint) |> Path.join("static/version.txt") |> File.read!() |> String.trim()
  ]
