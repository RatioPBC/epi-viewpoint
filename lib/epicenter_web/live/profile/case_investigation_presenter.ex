defmodule EpicenterWeb.Profile.CaseInvestigationPresenter do
  alias Epicenter.Format
  alias EpicenterWeb.Router.Helpers, as: Routes

  import Phoenix.LiveView.Helpers

  def history_items(case_investigation, person) do
    items = []

    items =
      if case_investigation.discontinue_reason != nil do
        [
          %{
            text: "Discontinued interview on #{Format.date_time(case_investigation.discontinued_at)}: #{case_investigation.discontinue_reason}",
            link:
              live_redirect(
                "Edit",
                to:
                  Routes.case_investigation_discontinue_path(
                    EpicenterWeb.Endpoint,
                    EpicenterWeb.CaseInvestigationDiscontinueLive,
                    person,
                    case_investigation
                  ),
                id: "edit-discontinue-case-investigation-link-001",
                class: "discontinue-case-investigation-link"
              )
          }
          | items
        ]
      else
        items
      end

    items
  end
end
