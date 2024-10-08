defmodule EpiViewpoint.Cases.SaveMergeTest do
  use EpiViewpoint.DataCase, async: true

  import EpiViewpoint.Test.RevisionAssertions
  import Euclid.Extra.Enum, only: [tids: 1]

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.AuditLog.Revision
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.Merge
  alias EpiViewpoint.Cases.Person
  alias EpiViewpoint.ContactInvestigations
  alias EpiViewpoint.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  setup do
    user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
    [user: user]
  end

  describe "identifying information" do
    test "emails, phones, and addresses from the duplicate person are copied to the canonical person", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.email_attrs(user, alice, "alice-email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, alice, "alice-phone", number: "111-111-1000") |> Cases.create_phone!()
      Test.Fixtures.address_attrs(user, alice, "alice-address", 1000, type: "home") |> Cases.create_address!()

      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      Test.Fixtures.email_attrs(user, billy, "billy-email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, billy, "billy-phone", number: "111-111-1002") |> Cases.create_phone!()
      Test.Fixtures.address_attrs(user, billy, "billy-address", 1001, type: "home") |> Cases.create_address!()

      Merge.merge([billy.id], into: alice.id, merge_conflict_resolutions: %{}, current_user: user)

      alice = alice |> Cases.preload_addresses() |> Cases.preload_emails() |> Cases.preload_phones()
      assert alice.phones |> contains("alice-phone")
      assert alice.phones |> contains("billy-phone")
      assert alice.emails |> contains("alice-email")
      assert alice.emails |> contains("billy-email")
      assert alice.addresses |> contains("alice-address")
      assert alice.addresses |> contains("billy-address")
    end

    test "when duplicate person and canonical person have the same phone number", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.email_attrs(user, alice, "alice-email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, alice, "alice-phone", number: "111-111-1000") |> Cases.create_phone!()
      Test.Fixtures.address_attrs(user, alice, "alice-address", 1000, type: "home") |> Cases.create_address!()

      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      Test.Fixtures.email_attrs(user, billy, "billy-email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, billy, "billy-phone", number: "111-111-1000") |> Cases.create_phone!()
      Test.Fixtures.address_attrs(user, billy, "billy-address", 1000, type: "home") |> Cases.create_address!()

      Merge.merge([billy.id], into: alice.id, merge_conflict_resolutions: %{}, current_user: user)

      alice = alice |> Cases.preload_addresses() |> Cases.preload_emails() |> Cases.preload_phones()
      assert alice.phones |> tids() == ["alice-phone"]
      assert alice.emails |> tids() == ["alice-email", "billy-email"]
      assert alice.addresses |> tids() == ["alice-address"]
    end

    test "when duplicate people have the same phone number", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.phone_attrs(user, alice, "alice-phone", number: "111-111-1000") |> Cases.create_phone!()

      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      Test.Fixtures.phone_attrs(user, billy, "billy-phone", number: "111-111-1111") |> Cases.create_phone!()

      cindy = Test.Fixtures.person_attrs(user, "cindy") |> Cases.create_person!()
      Test.Fixtures.phone_attrs(user, cindy, "cindy-phone", number: "111-111-1111") |> Cases.create_phone!()

      Merge.merge([billy.id, cindy.id], into: alice.id, merge_conflict_resolutions: %{}, current_user: user)

      alice = alice |> Cases.preload_phones()
      assert alice.phones |> Euclid.Extra.Enum.pluck(:number) == ["1111111000", "1111111111"]
    end

    test "when duplicate people have the same address fingerprint", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()

      alice_address =
        Test.Fixtures.address_attrs(user, alice, "alice-address", 1111, type: "home", address_fingerprint: "woof") |> Cases.create_address!()

      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      billy_address = Test.Fixtures.address_attrs(user, billy, "billy-address", 1000, type: "home") |> Cases.create_address!()

      cindy = Test.Fixtures.person_attrs(user, "cindy") |> Cases.create_person!()
      Test.Fixtures.address_attrs(user, cindy, "cindy-address", 1000, type: "home") |> Cases.create_address!()

      Merge.merge([billy.id, cindy.id], into: alice.id, merge_conflict_resolutions: %{}, current_user: user)

      alice = alice |> Cases.preload_addresses()

      assert alice.addresses |> Euclid.Extra.Enum.pluck(:address_fingerprint) |> Enum.sort() ==
               Enum.sort([
                 alice_address.address_fingerprint,
                 billy_address.address_fingerprint
               ])
    end

    test "when duplicate people have the same emails", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      alice_email = Test.Fixtures.email_attrs(user, alice, "alice-email") |> Cases.create_email!()

      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      billy_email = Test.Fixtures.email_attrs(user, billy, "billy-email") |> Cases.create_email!()

      cindy = Test.Fixtures.person_attrs(user, "cindy") |> Cases.create_person!()
      Test.Fixtures.email_attrs(user, alice, "billy-email") |> Cases.create_email!()

      Merge.merge([billy.id, cindy.id], into: alice.id, merge_conflict_resolutions: %{}, current_user: user)

      alice = alice |> Cases.preload_emails()

      assert alice.emails |> Euclid.Extra.Enum.pluck(:address) == [
               alice_email.address,
               billy_email.address
             ]
    end

    defp contains(list, tid) do
      Enum.find(list, &(&1.tid == tid)) != nil
    end
  end

  describe "merging the demographics" do
    defp create_person(tid, demographic_attrs, person_attrs \\ %{}) do
      {person_attrs, audit_meta} = Test.Fixtures.person_attrs(@admin, tid, person_attrs, demographics: false)

      {Map.put(person_attrs, :demographics, [demographic_attrs]), audit_meta}
      |> Cases.create_person!()
    end

    defp create_demographic(person, attrs) do
      attrs = %{source: "form", person_id: person.id} |> Map.merge(attrs)
      {:ok, _result} = {attrs, Test.Fixtures.admin_audit_meta()} |> Cases.create_demographic()
      person
    end

    defp reload_demographics(person) do
      Cases.get_person(person.id, @admin) |> Cases.preload_demographics() |> Person.coalesce_demographics()
    end

    test "when there are no merge conflict resolutions", %{user: user} do
      # we need layers of demographics to prove that they are still coalesced in the same
      # order after being transferred to Alice
      alice = create_person("alice", %{tid: "alice-1", source: "form", dob: ~D[2001-10-01], first_name: "no"})
      billy = create_person("billy", %{tid: "billy-2", source: "form", first_name: "yes-first-name", last_name: "Testuser-no"})
      billy |> create_demographic(%{tid: "billy-3", source: "form", last_name: "Testuser-yes", occupation: "no"})
      alice |> create_demographic(%{tid: "alice-4", source: "form", occupation: "yes-occupation"})
      cindy = create_person("cindy", %{tid: "cindy-5", source: "form", employment: "yes-employment"})

      Merge.merge([cindy.id, billy.id], into: alice.id, merge_conflict_resolutions: %{}, current_user: user)

      coalesced_alice = reload_demographics(alice)
      assert coalesced_alice[:dob] == ~D[2001-10-01]
      assert coalesced_alice[:first_name] == "no"
      assert coalesced_alice[:last_name] == "Testuser-yes"
      assert coalesced_alice[:occupation] == "yes-occupation"
      assert coalesced_alice[:employment] == "yes-employment"

      coalesced_billy = reload_demographics(billy)
      assert coalesced_billy[:dob] == nil
      assert coalesced_billy[:first_name] == "yes-first-name"
      assert coalesced_billy[:last_name] == "Testuser-yes"
      assert coalesced_billy[:occupation] == "no"

      coalesced_cindy = reload_demographics(cindy)
      assert coalesced_cindy[:employment] == "yes-employment"
    end

    test "when there are merge conflict resolutions", %{user: user} do
      katie = create_person("katie", %{tid: "katie", source: "form", first_name: "katie", dob: ~D[2001-01-01], preferred_language: "Spanish"})
      katy = create_person("katy", %{tid: "katy", source: "form", first_name: "katy", dob: ~D[2003-01-01], preferred_language: "English"})
      kate = create_person("kate", %{tid: "kate", source: "form", first_name: "kate", dob: ~D[2004-01-01], preferred_language: "Japanese"})

      merge_conflict_resolutions = %{first_name: "katie", dob: ~D[2001-01-01], preferred_language: "Spanish"}
      Merge.merge([katie.id, katy.id], into: kate.id, merge_conflict_resolutions: merge_conflict_resolutions, current_user: user)

      merged_kate = reload_demographics(kate)

      assert merged_kate[:first_name] == merge_conflict_resolutions[:first_name]
      assert merged_kate[:dob] == merge_conflict_resolutions[:dob]
      assert merged_kate[:preferred_language] == merge_conflict_resolutions[:preferred_language]
    end

    test "when only some fields conflict", %{user: user} do
      katie = create_person("katie", %{tid: "katie", source: "form", first_name: "katie", dob: ~D[2001-01-01], preferred_language: "English"})
      katy = create_person("katy", %{tid: "katy", source: "form", first_name: "katy", dob: ~D[2003-01-01], preferred_language: "English"})
      kate = create_person("kate", %{tid: "kate", source: "form", first_name: "kate", dob: ~D[2004-01-01], preferred_language: "English"})

      merge_conflict_resolutions = %{first_name: "katie", dob: ~D[2001-01-01]}
      Merge.merge([katie.id, katy.id], into: kate.id, merge_conflict_resolutions: merge_conflict_resolutions, current_user: user)

      merged_kate = reload_demographics(kate)

      assert merged_kate[:first_name] == merge_conflict_resolutions[:first_name]
      assert merged_kate[:dob] == merge_conflict_resolutions[:dob]
    end
  end

  describe "merging the contact investigations" do
    test "it moves contact investigations from the duplicate person to the canonical person", %{user: user} do
      sick_person = Test.Fixtures.person_attrs(user, "sick-person") |> Cases.create_person!()

      contact_investigation = create_contact_investigation(@admin, sick_person, %{}, %{}, %{tid: "contact-investigation-to-move"})
      duplicate_person = contact_investigation.exposed_person
      case_investigation = Cases.get_case_investigation(contact_investigation.exposing_case_id, @admin)

      canonical_person = Test.Fixtures.person_attrs(user, "canonical-person") |> Cases.create_person!()

      Merge.merge([duplicate_person.id], into: canonical_person.id, merge_conflict_resolutions: %{}, current_user: user)

      # contact investigation should have been moved
      contact_investigation = ContactInvestigations.get(contact_investigation.id, @admin) |> ContactInvestigations.preload_exposed_person()
      assert contact_investigation.exposed_person.id == canonical_person.id

      # canonical_person  should have the contact_investigation
      canonical_person = Cases.get_person(canonical_person.id, @admin) |> Cases.preload_contact_investigations(@admin)
      assert canonical_person.contact_investigations |> tids() == ["contact-investigation-to-move"]

      # case_investigation should show details for the canonical person instead of the duplicate person
      case_investigation = case_investigation |> Cases.preload_contact_investigations(@admin, false)
      assert case_investigation.contact_investigations |> tids() == ["contact-investigation-to-move"]

      # TODO check that the right revision is made for the contact investigation
    end

    defp create_contact_investigation(user, sick_person, lab_result_attrs, case_investigation_attrs, contact_investigation_attrs) do
      lab_result =
        Test.Fixtures.lab_result_attrs(sick_person, user, "lab_result", ~D[2020-08-07], lab_result_attrs)
        |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(sick_person, lab_result, user, "the contagious person's case investigation", case_investigation_attrs)
        |> Cases.create_case_investigation!()

      {:ok, contact_investigation} =
        {Test.Fixtures.contact_investigation_attrs(
           "contact_investigation",
           Map.put(contact_investigation_attrs, :exposing_case_id, case_investigation.id)
         ), Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      contact_investigation
    end
  end

  describe "merging the case_investigations" do
    test "it moves contact investigations from the duplicate person to the canonical person", %{user: user} do
      person = Test.Fixtures.person_attrs(@admin, "canonical") |> Cases.create_person!()

      lab_result =
        Test.Fixtures.lab_result_attrs(person, @admin, "lab_result", ~D[2021-02-10], %{
          result: "positive"
        })
        |> Cases.create_lab_result!()

      Test.Fixtures.case_investigation_attrs(
        person,
        lab_result,
        user,
        "case-investigation",
        %{name: "001"}
      )
      |> Cases.create_case_investigation!()

      duplicate_person = Test.Fixtures.person_attrs(@admin, "duplicate") |> Cases.create_person!()

      duplicate_lab_result =
        Test.Fixtures.lab_result_attrs(duplicate_person, @admin, "duplicate_lab_result", ~D[2021-02-10], %{
          result: "positive"
        })
        |> Cases.create_lab_result!()

      duplicate_case_investigation =
        Test.Fixtures.case_investigation_attrs(
          duplicate_person,
          duplicate_lab_result,
          @admin,
          "duplicate-case-investigation",
          %{name: "001"}
        )
        |> Cases.create_case_investigation!()

      Merge.merge([duplicate_person.id], into: person.id, merge_conflict_resolutions: %{}, current_user: user)

      person = Cases.get_person(person.id, @admin) |> Cases.preload_case_investigations()
      assert ["case-investigation", "duplicate-case-investigation"] == person.case_investigations |> Enum.map(& &1.tid)

      assert_recent_audit_log(duplicate_case_investigation, user,
        action: Revision.update_case_investigation_action(),
        event: Revision.save_merge_event()
      )
    end
  end

  describe "merging lab_results" do
    test "lab results are moved from the duplicates to the canonical person", %{user: user} do
      canonical = Test.Fixtures.person_attrs(user, "canonical") |> Cases.create_person!()
      duplicate1 = Test.Fixtures.person_attrs(user, "duplicate1") |> Cases.create_person!()
      duplicate2 = Test.Fixtures.person_attrs(user, "duplicate2") |> Cases.create_person!()

      result1 = Test.Fixtures.lab_result_attrs(duplicate1, user, "result1", ~D[2020-08-07]) |> Cases.create_lab_result!()
      result2 = Test.Fixtures.lab_result_attrs(duplicate2, user, "result2", ~D[2020-08-07]) |> Cases.create_lab_result!()

      Merge.merge([duplicate1.id, duplicate2.id], into: canonical.id, merge_conflict_resolutions: %{}, current_user: user)

      canonical = Cases.preload_lab_results(canonical)

      lab_result_ids = canonical.lab_results |> Enum.map(& &1.id)

      assert Enum.member?(lab_result_ids, result1.id)
      assert Enum.member?(lab_result_ids, result2.id)

      assert_recent_audit_log(result1, user, action: Revision.update_lab_result_action(), event: Revision.save_merge_event())
      assert_recent_audit_log(result2, user, action: Revision.update_lab_result_action(), event: Revision.save_merge_event())
    end

    test "when the lab results are exactly the same, it doesn't move them, and finishes the rest of the merge", %{user: user} do
      canonical = Test.Fixtures.person_attrs(user, "canonical") |> Cases.create_person!()
      duplicate1 = Test.Fixtures.person_attrs(user, "duplicate1") |> Cases.create_person!()
      duplicate2 = Test.Fixtures.person_attrs(user, "duplicate2") |> Cases.create_person!()

      result1 =
        Test.Fixtures.lab_result_attrs(duplicate1, user, "result1", ~D[2020-08-07], %{
          analyzed_on: ~D[2020-08-07],
          reported_on: ~D[2020-08-07],
          request_accession_number: "",
          request_facility_code: "",
          request_facility_name: "",
          result: "positive",
          sampled_on: ~D[2020-08-07],
          test_type: "a"
        })
        |> Cases.create_lab_result!()

      Test.Fixtures.lab_result_attrs(duplicate2, user, "result2", ~D[2020-08-07], %{
        analyzed_on: ~D[2020-08-07],
        reported_on: ~D[2020-08-07],
        request_accession_number: "",
        request_facility_code: "",
        request_facility_name: "",
        result: "positive",
        sampled_on: ~D[2020-08-07],
        test_type: "a"
      })
      |> Cases.create_lab_result!()

      Merge.merge([duplicate1.id, duplicate2.id], into: canonical.id, merge_conflict_resolutions: %{}, current_user: user)

      canonical = Cases.preload_lab_results(canonical)

      lab_result_ids = canonical.lab_results |> Enum.map(& &1.id)

      assert Enum.member?(lab_result_ids, result1.id)

      assert_recent_audit_log(result1, user, action: Revision.update_lab_result_action(), event: Revision.save_merge_event())
    end
  end

  describe "audit logging the merge" do
    # It would be more ideal if the objects the audit logs get tied to were the person
    # instead of the address, email, and phone objects themselves. This is a potential
    # improvement that we might want if we want to build UI for viewing the merge
    # history.
    test "it audit logs the creation of addresses/emails/phones", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.address_attrs(user, alice, "alice-address", 1000, type: "home") |> Cases.create_address!()
      Test.Fixtures.email_attrs(user, alice, "alice-email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, alice, "alice-phone", number: "111-111-1000") |> Cases.create_phone!()

      billy = Test.Fixtures.person_attrs(user, "billy") |> Cases.create_person!()
      Test.Fixtures.address_attrs(user, billy, "billy-address", 1001, type: "home") |> Cases.create_address!()
      Test.Fixtures.email_attrs(user, billy, "billy-email") |> Cases.create_email!()
      Test.Fixtures.phone_attrs(user, billy, "billy-phone", number: "111-111-1002") |> Cases.create_phone!()

      Merge.merge([billy.id], into: alice.id, merge_conflict_resolutions: %{}, current_user: user)

      alice = alice |> Cases.preload_addresses() |> Cases.preload_emails() |> Cases.preload_phones()

      %{addresses: [_, new_address], emails: [_, new_email], phones: [_, new_phone]} = alice

      assert_semi_recent_audit_log(new_address, user, Revision.create_address_action(), Revision.save_merge_event(), %{
        "person_id" => alice.id
      })

      assert_semi_recent_audit_log(new_email, user, Revision.create_email_action(), Revision.save_merge_event(), %{
        "person_id" => alice.id
      })

      assert_semi_recent_audit_log(new_phone, user, Revision.create_phone_action(), Revision.save_merge_event(), %{
        "person_id" => alice.id
      })
    end
  end
end
