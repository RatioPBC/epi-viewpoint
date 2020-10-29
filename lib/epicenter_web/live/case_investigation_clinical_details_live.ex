defmodule EpicenterWeb.CaseInvestigationClinicalDetailsLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, ok: 1]

  def mount(%{"id" => _id}, _session, socket) do
    socket
    |> assign_page_title(" Case Investigation Clinical Details")
    |> ok()
  end
end
