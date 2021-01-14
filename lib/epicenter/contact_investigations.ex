defmodule Epicenter.ContactInvestigations do
  alias Epicenter.AuditLog
  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias Epicenter.Repo

  def change(%ContactInvestigation{} = investigation, attrs),
    do: ContactInvestigation.changeset(investigation, attrs)

  def complete_interview(contact_investigation, author_id, %{interview_completed_at: interview_completed_at} = params)
      when not is_nil(interview_completed_at) do
    update(
      contact_investigation,
      {params,
       %AuditLog.Meta{
         author_id: author_id,
         reason_action: AuditLog.Revision.update_contact_investigation_action(),
         reason_event: AuditLog.Revision.complete_contact_investigation_interview_event()
       }}
    )
  end

  def create({attrs, audit_meta}),
    do: %ContactInvestigation{} |> change(attrs) |> AuditLog.insert(audit_meta)

  def get(id, user), do: AuditLog.get(ContactInvestigation, id, user)

  def preload_exposed_person(contact_investigations), do: contact_investigations |> Repo.preload(exposed_person: [:demographics, :phones])

  def preload_exposing_case(contact_investigations), do: contact_investigations |> Repo.preload(exposing_case: [person: [:demographics]])

  def preload_exposing_case(contact_investigations_or_nil, user) do
    contact_investigations_or_nil
    |> Repo.preload(exposing_case: [person: [:demographics]])
    |> log_case_investigations(user)
  end

  defp log_case_investigations(nil, _user), do: nil

  defp log_case_investigations(contact_investigations, user) when is_list(contact_investigations),
    do: contact_investigations |> Enum.map(&log_case_investigations(&1, user))

  defp log_case_investigations(contact_investigation, user) do
    contact_investigation.exposing_case |> AuditLog.view(user)
    contact_investigation
  end

  def update(%ContactInvestigation{} = investigation, {attrs, audit_meta}),
    do: investigation |> change(attrs) |> AuditLog.update(audit_meta)
end
