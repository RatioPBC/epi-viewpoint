defprotocol Epicenter.AuditLog.PhiLoggable do
  def phi_identifier(subject)
end

defimpl Epicenter.AuditLog.PhiLoggable, for: Epicenter.ContactInvestigations.ContactInvestigation do
  def phi_identifier(subject), do: subject.exposed_person_id
end
