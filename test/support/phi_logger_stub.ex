defmodule Epicenter.Test.PhiLoggerStub do
  @behaviour Epicenter.AuditLog.PhiLogger

  def info(_message, _metadata),
    do: :ok
end
