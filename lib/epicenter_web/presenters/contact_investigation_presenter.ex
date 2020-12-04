defmodule EpicenterWeb.Presenters.ContactInvestigationPresenter do
  import Phoenix.LiveView.Helpers
  import EpicenterWeb.PersonHelpers, only: [demographic_field: 2]

  alias EpicenterWeb.Router.Helpers, as: Routes

  def exposing_case_link(exposure) do
    exposing_person = exposure.exposing_case.person

    live_redirect(
      "\##{exposing_case_person_id(exposure)}",
      to:
        Routes.profile_path(
          EpicenterWeb.Endpoint,
          EpicenterWeb.ProfileLive,
          exposing_person
        ),
      data: [role: "visit-exposing-case-link"],
      class: "visit-exposing-case-link"
    )
  end

  defp exposing_case_person_id(exposure) do
    demographic_field(exposure.exposing_case.person, :external_id) ||
      exposure.exposing_case.person.id
  end
end
