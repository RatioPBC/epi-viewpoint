defmodule Epicenter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Epicenter.Repo,
      # Start the Telemetry supervisor
      EpicenterWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Epicenter.PubSub},
      # Start the Endpoint (http/https)
      EpicenterWeb.Endpoint
      # Start a worker by calling: Epicenter.Worker.start_link(arg)
      # {Epicenter.Worker, arg}
    ]

    :ok =
      :telemetry.attach(
        "logger-json-ecto",
        [:epicenter, :repo, :query],
        &LoggerJSON.Ecto.telemetry_logging_handler/4,
        :debug
      )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Epicenter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    EpicenterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
