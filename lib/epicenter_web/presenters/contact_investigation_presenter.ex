defmodule EpicenterWeb.Presenters.ContactInvestigationPresenter do
  import EpicenterWeb.PersonHelpers, only: [demographic_field: 2]

  def exposing_case_person_id(exposure) do
    demographic_field(exposure.exposing_case.person, :external_id) ||
      exposure.exposing_case.person.id
  end
end
