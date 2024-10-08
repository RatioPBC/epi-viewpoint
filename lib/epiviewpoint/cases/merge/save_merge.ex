defmodule EpiViewpoint.Cases.Merge.SaveMerge do
  alias EpiViewpoint.AuditLog
  alias EpiViewpoint.AuditLog.Revision
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.LabResult
  alias EpiViewpoint.Cases.Person
  alias EpiViewpoint.ContactInvestigations

  def merge(duplicate_person_ids, into: canonical_person_id, merge_conflict_resolutions: merge_conflict_resolutions, current_user: current_user) do
    people =
      Enum.map(duplicate_person_ids, fn duplicate_person_id ->
        Cases.get_person_without_audit_logging(duplicate_person_id) |> Cases.preload_demographics()
      end)

    canonical_person = Cases.get_person_without_audit_logging(canonical_person_id)

    merge_contact_info(people, canonical_person, current_user)
    merge_demographics(people, canonical_person, merge_conflict_resolutions, current_user)
    merge_contact_investigations(people, canonical_person, current_user)
    merge_case_investigations(people, canonical_person, current_user)
    mark_duplicate_people_merged(people, canonical_person, current_user)
    merge_lab_results(people, canonical_person, current_user)
  end

  defp merge_contact_info(people, canonical_person, current_user) do
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

      canonical_person_email_address = canonical_person.emails |> Enum.map(& &1.address)

      for email <- duplicate_person.emails do
        attrs = %{Map.from_struct(email) | person_id: canonical_person.id}

        if !(canonical_person_email_address |> Enum.member?(email.address)) do
          Cases.create_email!({attrs, audit_meta(current_user, Revision.create_email_action())})
        end
      end

      canonical_person_phone_numbers = canonical_person.phones |> Enum.map(& &1.number)

      for phone <- duplicate_person.phones do
        attrs = %{Map.from_struct(phone) | person_id: canonical_person.id}

        if !(canonical_person_phone_numbers |> Enum.member?(phone.number)) do
          Cases.create_phone!({attrs, audit_meta(current_user, Revision.create_phone_action())})
        end
      end
    end
  end

  defp merge_demographics(people, canonical_person, merge_conflict_resolutions, current_user) when merge_conflict_resolutions == %{} do
    coalesce_canonical_person = canonical_person |> Cases.preload_demographics() |> Person.coalesce_demographics()

    default_conflict_resolutions = %{
      :dob => coalesce_canonical_person.dob,
      :first_name => coalesce_canonical_person.first_name,
      :last_name => coalesce_canonical_person.last_name,
      :preferred_language => coalesce_canonical_person.preferred_language
    }

    merge_demographics(people, canonical_person, default_conflict_resolutions, current_user)
  end

  defp merge_demographics(people, canonical_person, merge_conflict_resolutions, current_user) do
    # 1. create but don't insert a new demographics snapshot row for each duplicate person
    #    by coalescing the demographics on each duplicate person respectively
    # 2. move all demographics rows from the duplicate people to the canonical person
    # 3. commit the flattened snapshot demographics to their duplicate person
    #    (so that they still have a name)
    # 4. Add a demographics entry to the canonical person with the merge conflict resolutions
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

    attrs =
      %{}
      |> Map.put(:first_name, merge_conflict_resolutions[:first_name])
      |> Map.put(:dob, merge_conflict_resolutions[:dob])
      |> Map.put(:preferred_language, merge_conflict_resolutions[:preferred_language])
      |> Map.put(:person_id, canonical_person.id)
      |> Map.put(:source, "form")
      |> Enum.filter(fn {_k, v} -> v != nil end)
      |> Enum.into(%{})

    Cases.create_demographic({attrs, audit_meta(current_user, Revision.insert_demographics_action())})
  end

  defp merge_contact_investigations(people, canonical_person, current_user) do
    for duplicate_person <- people do
      duplicate_person =
        duplicate_person
        |> Cases.preload_contact_investigations(current_user, false)

      for contact_investigation <- duplicate_person.contact_investigations do
        ContactInvestigations.merge(
          contact_investigation,
          canonical_person.id,
          audit_meta(current_user, Revision.update_contact_investigation_action())
        )
      end
    end
  end

  defp merge_case_investigations(people, canonical_person, current_user) do
    for duplicate_person <- people do
      duplicate_person =
        duplicate_person
        |> Cases.preload_case_investigations()

      for case_investigation <- duplicate_person.case_investigations do
        Cases.merge_case_investigations(
          case_investigation,
          canonical_person.id,
          audit_meta(current_user, Revision.update_case_investigation_action())
        )
      end
    end
  end

  defp merge_lab_results(people, canonical_person, current_user) do
    for duplicate_person <- people do
      duplicate_person = duplicate_person |> Cases.preload_lab_results()

      canonical_person = canonical_person.id |> Cases.get_person_without_audit_logging() |> Cases.preload_lab_results()
      canonical_person_fingerprints = canonical_person.lab_results |> Enum.map(& &1.fingerprint)

      for lab_result <- duplicate_person.lab_results do
        changeset = lab_result |> LabResult.changeset_for_merge(canonical_person.id)
        fingerprint = changeset |> LabResult.generate_fingerprint()

        if Enum.find(canonical_person_fingerprints, fn fp -> fp == fingerprint end) == nil do
          lab_result |> Cases.reassociate_lab_result(canonical_person.id, audit_meta(current_user, Revision.update_lab_result_action()))
        end
      end
    end
  end

  defp mark_duplicate_people_merged(duplicate_people, canonical_person, current_user) do
    Cases.merge_people(
      duplicate_people,
      canonical_person.id,
      current_user,
      audit_meta(current_user, AuditLog.Revision.merge_people_action())
    )
  end

  defp audit_meta(current_user, action) do
    %AuditLog.Meta{
      author_id: current_user.id,
      reason_action: action,
      reason_event: Revision.save_merge_event()
    }
  end
end
