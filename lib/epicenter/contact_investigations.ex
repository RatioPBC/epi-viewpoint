defmodule Epicenter.ContactInvestigations do
  alias Epicenter.AuditingRepo
  alias Epicenter.AuditLog
  alias Epicenter.Cases.Person
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
    do: %ContactInvestigation{} |> change(attrs) |> AuditingRepo.insert(audit_meta)

  def get(id, user), do: AuditingRepo.get(ContactInvestigation, id, user)

  def preload_exposed_person(contact_investigations), do: contact_investigations |> Repo.preload(exposed_person: [:demographics, :phones])

  def preload_exposing_case(contact_investigations), do: contact_investigations |> Repo.preload(exposing_case: [person: [:demographics]])

  def preload_exposing_case(contact_investigations_or_nil, user) do
    contact_investigations_or_nil
    |> Repo.preload(exposing_case: [person: [:demographics]])
    |> log_case_investigations(user)
  end

  def list_exposed_people(filter, user, reject_archived_people: reject_archived_people),
    do:
      Person.Query.filter_with_contact_investigation(filter) |> Person.Query.reject_archived_people(reject_archived_people) |> AuditingRepo.all(user)

  defp log_case_investigations(nil, _user), do: nil

  defp log_case_investigations(contact_investigations, user) when is_list(contact_investigations),
    do: contact_investigations |> Enum.map(&log_case_investigations(&1, user))

  defp log_case_investigations(contact_investigation, user) do
    contact_investigation.exposing_case |> AuditingRepo.view(user)
    contact_investigation
  end

  def update(%ContactInvestigation{} = investigation, {attrs, audit_meta}),
    do: investigation |> change(attrs) |> AuditingRepo.update(audit_meta)

  def merge(%ContactInvestigation{} = investigation, canonical_person_id, audit_meta),
    do:
      investigation
      |> ContactInvestigation.changeset_for_merge(canonical_person_id)
      |> AuditingRepo.update(audit_meta)
end
