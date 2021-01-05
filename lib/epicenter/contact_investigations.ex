defmodule Epicenter.ContactInvestigations do
  alias Epicenter.AuditLog
  alias Epicenter.ContactInvestigations.ContactInvestigation
  alias Epicenter.Repo

  def change(%ContactInvestigation{} = investigation, attrs),
    do: ContactInvestigation.changeset(investigation, attrs)

  def complete_interview(contact_investigation, author_id, params) do
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

  def get(id), do: ContactInvestigation |> Repo.get(id)

  def preload_exposed_person(contact_investigations), do: contact_investigations |> Repo.preload(exposed_person: [:demographics, :phones])
  def preload_exposing_case(contact_investigations), do: contact_investigations |> Repo.preload(exposing_case: [person: [:demographics]])

  def update(%ContactInvestigation{} = investigation, {attrs, audit_meta}),
    do: investigation |> change(attrs) |> AuditLog.update(audit_meta)
end
