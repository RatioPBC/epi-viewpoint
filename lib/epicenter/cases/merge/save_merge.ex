defmodule Epicenter.Cases.Merge.SaveMerge do
  alias Epicenter.Cases
  alias Epicenter.AuditLog
  alias Epicenter.AuditLog.Revision

  def merge(people, into: canonical_person, with_attrs: _into_person_attrs, current_user: current_user) do
    for duplicate_person <- people do
      duplicate_person = duplicate_person |> Cases.preload_addresses() |> Cases.preload_emails() |> Cases.preload_phones()

      for address <- duplicate_person.addresses do
        attrs = %{Map.from_struct(address) | person_id: canonical_person.id}
        Cases.create_address!({attrs, audit_meta(current_user, Revision.create_address_action())})
      end

      for email <- duplicate_person.emails do
        attrs = %{Map.from_struct(email) | person_id: canonical_person.id}
        Cases.create_email!({attrs, audit_meta(current_user, Revision.create_email_action())})
      end

      for phone <- duplicate_person.phones do
        attrs = %{Map.from_struct(phone) | person_id: canonical_person.id}

        Cases.create_phone!({attrs, audit_meta(current_user, Revision.create_phone_action())})
      end
    end
  end

  defp audit_meta(current_user, action) do
    %AuditLog.Meta{
      author_id: current_user.id,
      reason_action: action,
      reason_event: Revision.save_merge_event()
    }
  end
end
