defmodule EpicenterWeb.PeopleLive.Edit do
  use EpicenterWeb, :live_view

  alias Epicenter.Cases

  def mount(_params, _session, socket) do
    if connected?(socket),
      do: Cases.subscribe()

    socket |> ok()
  end

  defp ok(socket),
    do: {:ok, socket}
end
