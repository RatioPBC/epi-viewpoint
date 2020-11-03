defmodule EpicenterWeb.ErrorHandler do
  defmacro __using__(_opts) do
    quote do
      defp handle_errors(conn, %{kind: _kind, reason: reason, stack: stack}) do
        Epicenter.ErrorReporter.report(reason, stack)
        conn
      end
    end
  end
end
