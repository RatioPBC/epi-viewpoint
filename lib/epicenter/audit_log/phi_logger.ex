defmodule Epicenter.AuditLog.PhiLogger do
  require Logger

  @callback info(binary(), keyword(), keyword()) :: atom()
  def info(message, metadata, _unlogged_metatdata) do
    Logger.info(message, metadata)
  end
end
