defmodule Epicenter.MixProject do
  use Mix.Project

  def project do
    [
      app: :epicenter,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Epicenter.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      local_or_remote(:remote, :euclid, version: "~> 1.0", organization: "geometer", path: System.get_env("EUCLID_PATH", "../euclid")),
      {:bcrypt_elixir, "~> 2.1.0"},
      {:ecto_sql, "~> 3.5"},
      {:eqrcode, "~> 0.1.7"},
      {:floki, ">= 0.0.0", only: :test},
      {:gettext, "~> 0.11"},
      {:inflex, "~> 2.1"},
      {:jason, "~> 1.0"},
      {:mix_audit, "~> 0.1", runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:mox, "~> 1.0"},
      {:nimble_csv, "~> 0.7"},
      {:nimble_totp, "~> 0.1.0"},
      {:number, "~> 1.0.3"},
      {:phoenix, "~> 1.5.4"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.2"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.13.0"},
      {:phoenix_slime, "~> 0.13.1"},
      {:phoenix_slime_live_view_collocated_template, "~> 0.1.0"},
      {:phx_gen_auth, "~> 0.5.0"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      {:table_rex, "~> 3.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "deps.get": ["deps.get", "deps.audit"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  defp local_or_remote(:local, package, options) do
    {package, options |> Keyword.delete(:organization) |> Keyword.delete(:version)}
  end

  defp local_or_remote(:remote, package, options) do
    {package, options |> Keyword.get(:version), options |> Keyword.delete(:path) |> Keyword.delete(:version)}
  end
end
