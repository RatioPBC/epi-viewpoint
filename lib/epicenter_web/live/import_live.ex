defmodule EpicenterWeb.ImportLive do
  use EpicenterWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, uploading: false)}
  end
end
