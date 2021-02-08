defmodule Epicenter.Cases.Merge.SaveMerge do
  alias Epicenter.AuditLog
  alias Epicenter.AuditLog.Revision
  alias Epicenter.Cases
  alias Epicenter.Cases.Person

  def merge(people, into: canonical_person, with_attrs: _into_person_attrs, current_user: current_user) do
    for duplicate_person <- people do
      duplicate_person = duplicate_person |> Cases.preload_addresses() |> Cases.preload_emails() |> Cases.preload_phones()
      canonical_person = canonical_person |> Cases.preload_addresses() |> Cases.preload_emails() |> Cases.preload_phones()

      canonical_person_address_fingerprints = canonical_person.addresses |> Enum.map(& &1.address_fingerprint)

      for address <- duplicate_person.addresses do
        attrs = %{Map.from_struct(address) | person_id: canonical_person.id}

        if !(canonical_person_address_fingerprints |> Enum.member?(address.address_fingerprint)) do
          Cases.create_address!({attrs, audit_meta(current_user, Revision.create_address_action())})
        end
      end

      for email <- duplicate_person.emails do
        attrs = %{Map.from_struct(email) | person_id: canonical_person.id}
        Cases.create_email!({attrs, audit_meta(current_user, Revision.create_email_action())})
      end

      canonical_person_phone_numbers = canonical_person.phones |> Enum.map(& &1.number)

      for phone <- duplicate_person.phones do
        attrs = %{Map.from_struct(phone) | person_id: canonical_person.id}

        if !(canonical_person_phone_numbers |> Enum.member?(phone.number)) do
          Cases.create_phone!({attrs, audit_meta(current_user, Revision.create_phone_action())})
        end
      end
    end

    merge_demographics(people, canonical_person, current_user)
  end

  defp merge_demographics(people, canonical_person, current_user) do
    people =
      Enum.map(people, fn duplicate_person ->
        Cases.force_reload_person(duplicate_person) |> Cases.preload_demographics()
      end)

    flattened_demographics =
      Enum.reduce(people, %{}, fn duplicate_person, acc ->
        Map.put(acc, duplicate_person.id, Person.coalesce_demographics(duplicate_person))
      end)

    for duplicate_person <- people do
      for demographic <- duplicate_person.demographics do
        demographic
        |> Cases.update_demographic({%{person_id: canonical_person.id}, audit_meta(current_user, Revision.update_demographics_action())})
      end
    end

    for {_duplicate_person, coalesced_demographics} <- flattened_demographics do
      attrs = %{coalesced_demographics | source: "form"}

      attrs =
        if Map.get(attrs, :ethnicity) do
          %{ethnicity: ethnicity} = attrs
          Map.put(attrs, :ethnicity, Map.from_struct(ethnicity))
        else
          attrs
        end

      Cases.create_demographic({attrs, audit_meta(current_user, Revision.insert_demographics_action())})
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
