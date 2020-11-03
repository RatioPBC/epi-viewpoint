defmodule Epicenter.ErrorReporter do
  require Logger
  alias LoggerJSON.Formatters.GoogleErrorReporter

  def report(error, stacktrace) do
    GoogleErrorReporter.report(error, stacktrace, serviceContext: service_context())
  end

  defp service_context do
    [service: "viewpoint-construction"]
  end
end
