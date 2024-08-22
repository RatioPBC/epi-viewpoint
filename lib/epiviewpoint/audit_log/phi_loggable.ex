defprotocol EpiViewpoint.AuditLog.PhiLoggable do
  def phi_identifier(subject)
end

defimpl EpiViewpoint.AuditLog.PhiLoggable, for: EpiViewpoint.ContactInvestigations.ContactInvestigation do
  def phi_identifier(subject), do: subject.exposed_person_id
end

defimpl EpiViewpoint.AuditLog.PhiLoggable, for: EpiViewpoint.Cases.CaseInvestigation do
  def phi_identifier(subject), do: subject.person_id
end

defimpl EpiViewpoint.AuditLog.PhiLoggable, for: EpiViewpoint.Cases.Person do
  def phi_identifier(subject), do: subject.id
end

defimpl EpiViewpoint.AuditLog.PhiLoggable, for: EpiViewpoint.Cases.Place do
  def phi_identifier(subject), do: subject.id
end
