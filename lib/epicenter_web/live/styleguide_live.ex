defmodule EpicenterWeb.StyleguideLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.IconView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, show_nav: false)}
  end
end
