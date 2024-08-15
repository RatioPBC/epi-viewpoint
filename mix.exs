defmodule Epicenter.MixProject do
  use Mix.Project

  def project do
    [
      app: :epicenter,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [epicenter: [steps: [:assemble, &update_tzdata/1]]]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Epicenter.Application, []},
      extra_applications: [:jason, :logger_json, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp update_tzdata(release) do
    {:ok, _started} = Application.ensure_all_started(:tzdata)

    case Tzdata.ReleaseUpdater.poll_for_update() do
      :do_nothing -> release
      :ok -> release
      {:error, error} -> {:error, error}
    end
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      local_or_remote(:remote, :euclid, version: "~> 0.1", path: System.get_env("EUCLID_PATH", "../euclid")),
      {:bcrypt_elixir, "~> 2.1"},
      {:cowboy_telemetry, "~> 0.4"},
      {:ecto_sql, "~> 3.11"},
      {:eqrcode, "~> 0.1"},
      {:floki, ">= 0.0.0", only: :test},
      {:gettext, "~> 0.11"},
      {:inflex, "~> 2.1"},
      {:jason, "~> 1.0"},
      {:logger_json, "~> 4.3"},
      {:mix_audit, "~> 1.0", runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:mox, "~> 1.0"},
      {:nimble_csv, "~> 1.0"},
      {:nimble_totp, "~> 0.1"},
      {:number, "~> 1.0"},
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_integration, git: "https://github.com/RatioPBC/phoenix_integration", ref: "82c94b3a09633ca8c6cda1354c4dad97065815f9", only: :test},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0-rc.6"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_view, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      {:sobelow, "~> 0.8", only: [:dev, :test]},
      {:table_rex, "~> 3.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 1.0"},
      {:timex, "~> 3.6"},
      {:ua_parser, "~> 1.8"},
      {:zarex, "~> 1.0"}
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
    {package, options |> Keyword.delete(:version)}
  end

  defp local_or_remote(:remote, package, options) do
    {package, options |> Keyword.get(:version), options |> Keyword.delete(:path) |> Keyword.delete(:version)}
  end
end
