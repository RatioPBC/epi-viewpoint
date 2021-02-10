defmodule Epicenter.AuditLog.PhiLogger do
  require Logger

  @callback info(binary(), keyword()) :: atom()
  def(info(message, metadata)) do
    Logger.info(message, metadata)
  end
end
