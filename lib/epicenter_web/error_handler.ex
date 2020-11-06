defmodule EpicenterWeb.ErrorHandler do
  alias LoggerJSON.Formatters.GoogleErrorReporter

  defmacro __using__(_opts) do
    quote do
      defp handle_errors(conn, %{kind: kind, reason: reason, stack: stacktrace}) do
        GoogleErrorReporter.report(kind, reason, stacktrace)
        conn
      end
    end
  end
end
