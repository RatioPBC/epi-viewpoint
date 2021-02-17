defprotocol Epicenter.AuditLog.PhiLoggable do
  def phi_identifier(subject)
end

defimpl Epicenter.AuditLog.PhiLoggable, for: Epicenter.ContactInvestigations.ContactInvestigation do
  def phi_identifier(subject), do: subject.exposed_person_id
end

defimpl Epicenter.AuditLog.PhiLoggable, for: Epicenter.Cases.CaseInvestigation do
  def phi_identifier(subject), do: subject.person_id
end

defimpl Epicenter.AuditLog.PhiLoggable, for: Epicenter.Cases.Person do
  def phi_identifier(subject), do: subject.id
end

defimpl Epicenter.AuditLog.PhiLoggable, for: Epicenter.Cases.Place do
  def phi_identifier(subject), do: subject.id
end
