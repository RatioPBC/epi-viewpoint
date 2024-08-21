defmodule EpiViewpoint.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      EpiViewpoint.Repo,
      # Start the Telemetry supervisor
      EpiViewpointWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: EpiViewpoint.PubSub},
      # Start the Endpoint (http/https)
      EpiViewpointWeb.Endpoint
      # Start a worker by calling: EpiViewpoint.Worker.start_link(arg)
      # {EpiViewpoint.Worker, arg}
    ]

    :ok =
      :telemetry.attach(
        "logger-json-ecto",
        [:epiviewpoint, :repo, :query],
        &LoggerJSON.Ecto.telemetry_logging_handler/4,
        :debug
      )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EpiViewpoint.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    EpiViewpointWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
