defmodule Epicenter.ErrorReporter do
  require Logger
  alias LoggerJSON.Formatters.GoogleErrorReporter

  def report(error, stacktrace) do
    GoogleErrorReporter.report(error, stacktrace, serviceContext: service_context())
  end

  defp service_context do
    Application.fetch_env!(:epicenter, Epicenter.ErrorReporter)[:service_context]
  end
end
