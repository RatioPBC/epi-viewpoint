defmodule EpiViewpoint.Test.PhiLoggerStub do
  @behaviour EpiViewpoint.AuditLog.PhiLogger

  def info(_message, _metadata, _unlogged_metadata),
    do: :ok
end
