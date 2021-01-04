defmodule Epicenter.ContactInvestigations do
  alias Epicenter.AuditLog
  alias Epicenter.Cases.ContactInvestigation

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

  def update(%ContactInvestigation{} = investigation, {attrs, audit_meta}),
    do: investigation |> change(attrs) |> AuditLog.update(audit_meta)
end
