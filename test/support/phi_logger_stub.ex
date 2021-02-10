defmodule Epicenter.Test.PhiLoggerStub do
  @behaviour Epicenter.AuditLog.PhiLogger

  def info(_message, _metadata, _unlogged_metadata),
    do: :ok
end
