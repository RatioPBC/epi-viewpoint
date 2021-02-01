defmodule EpicenterWeb.Presenters.ContactInvestigationPresenter do
  import Phoenix.LiveView.Helpers
  import EpicenterWeb.PersonHelpers, only: [demographic_field: 2]

  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias Epicenter.ContactInvestigations
  alias EpicenterWeb.Format
  alias EpicenterWeb.Presenters.PeoplePresenter
  alias EpicenterWeb.Router.Helpers, as: Routes

  def exposing_case_link(contact_investigation) do
    exposing_person = contact_investigation.exposing_case.person

    live_redirect(
      "\##{exposing_case_person_id(contact_investigation)}",
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

  defp exposing_case_person_id(contact_investigation) do
    demographic_field(contact_investigation.exposing_case.person, :external_id) ||
      contact_investigation.exposing_case.person.id
  end

  def history_items(contact_investigation) do
    [
      interview_started_at_history(contact_investigation),
      interview_completed_at_history(contact_investigation),
      interview_discontinued_at_history(contact_investigation)
    ]
    |> Enum.filter(&Function.identity/1)
  end

  defp interview_started_at_history(%{interview_started_at: nil}), do: nil

  defp interview_started_at_history(contact_investigation) do
    %{
      text: "Started interview with #{with_interviewee_name(contact_investigation)} on #{format_date(contact_investigation.interview_started_at)}",
      link:
        link_if_editable(
          contact_investigation.exposed_person,
          live_redirect(
            "Edit",
            to:
              Routes.contact_investigation_start_interview_path(
                EpicenterWeb.Endpoint,
                EpicenterWeb.ContactInvestigationStartInterviewLive,
                contact_investigation
              ),
            class: "contact-investigation-link",
            data: [role: "contact-investigation-start-interview-edit-link"]
          )
        )
    }
  end

  defp interview_completed_at_history(%{interview_completed_at: nil}), do: nil

  defp interview_completed_at_history(contact_investigation) do
    %{
      text: "Completed interview on #{format_date(contact_investigation.interview_completed_at)}",
      link:
        link_if_editable(
          contact_investigation.exposed_person,
          live_redirect(
            "Edit",
            to:
              Routes.contact_investigation_complete_interview_path(
                EpicenterWeb.Endpoint,
                :complete_contact_investigation,
                contact_investigation
              ),
            class: "contact-investigation-link",
            data: [role: "contact-investigation-complete-interview-edit-link"]
          )
        )
    }
  end

  defp interview_discontinued_at_history(%{interview_discontinued_at: nil}), do: nil

  defp interview_discontinued_at_history(contact_investigation) do
    %{
      text:
        "Discontinued interview on #{format_date(contact_investigation.interview_discontinued_at)}: #{
          contact_investigation.interview_discontinue_reason
        }",
      link:
        live_redirect(
          "Edit",
          to:
            Routes.contact_investigation_discontinue_path(
              EpicenterWeb.Endpoint,
              EpicenterWeb.ContactInvestigationDiscontinueLive,
              contact_investigation
            ),
          class: "contact-investigation-link",
          data: [role: "contact-investigation-discontinue-interview-edit-link"]
        )
    }
  end

  defp link_if_editable(person, link) do
    if PeoplePresenter.is_editable?(person) do
      link
    else
      []
    end
  end

  def quarantine_history_items(contact_investigation) do
    [
      quarantine_dates_history(contact_investigation),
      quarantine_conclusion(contact_investigation)
    ]
    |> Enum.filter(&Function.identity/1)
  end

  defp quarantine_dates_history(%{quarantine_monitoring_ends_on: nil, quarantine_monitoring_starts_on: nil}),
    do: nil

  defp quarantine_dates_history(contact_investigation) do
    %{
      text:
        "Quarantine dates: #{Format.date(contact_investigation.quarantine_monitoring_starts_on)} - #{
          Format.date(contact_investigation.quarantine_monitoring_ends_on)
        }",
      link:
        link_if_editable(
          contact_investigation.exposed_person,
          live_redirect(
            "Edit",
            to:
              Routes.contact_investigation_quarantine_monitoring_path(
                EpicenterWeb.Endpoint,
                EpicenterWeb.ContactInvestigationQuarantineMonitoringLive,
                contact_investigation
              ),
            class: "contact-investigation-link",
            data: [role: "edit-contact-investigation-quarantine-monitoring-link"]
          )
        )
    }
  end

  defp quarantine_conclusion(%{quarantine_concluded_at: nil}), do: nil

  defp quarantine_conclusion(contact_investigation) do
    %{
      text:
        "Concluded quarantine monitoring on #{Format.date(contact_investigation.quarantine_concluded_at)}: #{
          Gettext.gettext(Epicenter.Gettext, contact_investigation.quarantine_conclusion_reason)
        }",
      link:
        link_if_editable(
          contact_investigation.exposed_person,
          live_redirect(
            "Edit",
            to:
              Routes.contact_investigation_conclude_quarantine_monitoring_path(
                EpicenterWeb.Endpoint,
                EpicenterWeb.ContactInvestigationConcludeQuarantineMonitoringLive,
                contact_investigation
              ),
            class: "contact-investigation-link",
            data: [role: "conclude-contact-investigation-quarantine-monitoring-edit-link"]
          )
        )
    }
  end

  defp format_date(date),
    do: date |> Format.date_time_with_presented_time_zone()

  defp with_interviewee_name(%ContactInvestigation{interview_proxy_name: nil} = contact_investigation),
    do:
      contact_investigation
      |> ContactInvestigations.preload_exposed_person()
      |> Map.get(:exposed_person)
      |> Cases.preload_demographics()
      |> Format.person()

  defp with_interviewee_name(%ContactInvestigation{interview_proxy_name: interview_proxy_name}),
    do: "proxy #{interview_proxy_name}"
end
