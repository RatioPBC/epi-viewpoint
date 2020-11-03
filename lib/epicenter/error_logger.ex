defmodule Epicenter.ErrorLogger do
  require Logger
  @errorType "type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent"

  def log_error(error, stacktrace) do
    format_error_with_stacktrace(error, stacktrace)
    |> Logger.error(["@type": @errorType])
  end

  defp format_error_with_stacktrace(error, stacktrace) do
    [format_error(error) | Enum.map(stacktrace, &format_line/1)]
    |> Enum.join("\n")
  end

  defp format_error(error) do
    error_name = to_string(error.__struct__)
    "#{error_name}: #{Exception.message(error)}"
  end

  defp format_line({module, function, arity, [file: file, line: line]}) do
    "\t#{file}:#{line}:in `#{module}.#{function}/#{arity}'"
  end
end
