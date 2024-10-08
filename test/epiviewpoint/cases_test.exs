defmodule EpiViewpoint.CasesTest do
  use EpiViewpoint.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1, pluck: 2]

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.LabResult
  alias EpiViewpoint.Cases.Person
  alias EpiViewpoint.Cases.Import.ImportInfo
  alias EpiViewpoint.ContactInvestigations
  alias EpiViewpoint.Extra
  alias EpiViewpoint.Test
  alias EpiViewpoint.Test.AuditLogAssertions

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "importing" do
    defp first_names() do
      Cases.list_people(:all, user: @admin, reject_archived_people: true)
      |> Cases.preload_demographics()
      |> Enum.map(&(&1.demographics |> List.first() |> Map.get(:first_name)))
    end

    test "import_lab_results imports lab results and creates lab_result and person records" do
      {:ok,
       %ImportInfo{
         imported_people: people,
         imported_lab_result_count: 2,
         imported_person_count: 2,
         total_lab_result_count: 2,
         total_person_count: 2
       }} =
        %{
          file_name: "test.csv",
          contents: """
          search_firstname_2 , search_lastname_1 , dateofbirth_8 , datecollected_36 , resultdate_42 , result_39 , person_tid
          Alice              , Testuser          , 01/01/1970    , 06/01/2020       , 06/03/2020    , positive  , alice
          Billy              , Testuser          , 03/01/1990    , 06/06/2020       , 06/07/2020    , negative  , billy
          """
        }
        |> Cases.import_lab_results(@admin)

      assert people |> tids() == ["alice", "billy"]

      first_names() |> assert_eq(["Alice", "Billy"], ignore_order: true)
      Cases.list_lab_results() |> Enum.map(& &1.result) |> assert_eq(["positive", "negative"], ignore_order: true)
    end
  end

  describe "lab results" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

      %{creator: creator}
    end

    setup [:make_person]
    defp make_person(%{with_person: true, creator: creator}), do: [person: Test.Fixtures.person_attrs(creator, "alice") |> Cases.create_person!()]
    defp make_person(_), do: :ok

    @tag with_person: true
    test "create_lab_result! creates a lab result", %{creator: creator, person: person} do
      lab_result = Test.Fixtures.lab_result_attrs(person, creator, "result1", "06-01-2020") |> Cases.create_lab_result!()

      assert lab_result.request_accession_number == "accession-result1"
      assert lab_result.request_facility_code == "facility-result1"
      assert lab_result.request_facility_name == "result1 Lab, Inc."
      assert lab_result.result == "positive"
      assert lab_result.sampled_on == ~D[2020-06-01]
      assert lab_result.tid == "result1"
    end

    @tag with_person: true
    test "create_lab_result! results in a correct revision count", %{creator: creator, person: person} do
      lab_result = Test.Fixtures.lab_result_attrs(person, creator, "result1", "06-01-2020") |> Cases.create_lab_result!()

      assert_revision_count(lab_result, 1)
    end

    @tag with_person: true
    test "create_lab_result! results in a correct audit log", %{person: person, creator: creator} do
      lab_result = Test.Fixtures.lab_result_attrs(person, creator, "result1", "06-01-2020") |> Cases.create_lab_result!()

      assert_recent_audit_log(lab_result, creator, %{
        "person_id" => person.id,
        "request_accession_number" => "accession-result1",
        "request_facility_code" => "facility-result1",
        "request_facility_name" => "result1 Lab, Inc.",
        "result" => "positive",
        "sampled_on" => "2020-06-01",
        "tid" => "result1"
      })
    end

    @tag with_person: true
    test "list_lab_results sorts by sample date", %{person: person, creator: creator} do
      Test.Fixtures.lab_result_attrs(person, creator, "newer", "06-03-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(person, creator, "older", "06-01-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(person, creator, "middle", "06-02-2020") |> Cases.create_lab_result!()

      Cases.list_lab_results() |> tids() |> assert_eq(~w{older middle newer})
    end

    test "upsert_lab_result! creates a lab result if one doesn't exist (based on person_id and all lab result fields)" do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      person_1 = Test.Fixtures.person_attrs(creator, "person-1") |> Cases.create_person!()
      person_2 = Test.Fixtures.person_attrs(creator, "person-2") |> Cases.create_person!()

      update_first_elem = fn {first, second}, func -> {func.(first), second} end

      Test.Fixtures.lab_result_attrs(person_1, creator, "result-1", "01/01/2020")
      |> update_first_elem.(&Map.put(&1, :tid, "person-1-result-1"))
      |> Cases.upsert_lab_result!()

      Test.Fixtures.lab_result_attrs(person_1, creator, "result-2", "01/01/2020")
      |> update_first_elem.(&Map.put(&1, :tid, "person-1-result-2"))
      |> Cases.upsert_lab_result!()

      Test.Fixtures.lab_result_attrs(person_1, creator, "result-2", "01/01/2020")
      |> update_first_elem.(&Map.put(&1, :tid, "person-1-result-2-dupe"))
      |> Cases.upsert_lab_result!()

      Test.Fixtures.lab_result_attrs(person_2, creator, "result-2", "01/01/2020")
      |> update_first_elem.(&Map.put(&1, :tid, "person-2-result-2"))
      |> Cases.upsert_lab_result!()

      [person_1 = %{tid: "person-1"}, person_2 = %{tid: "person-2"}] =
        Cases.list_people(:all, user: @admin, reject_archived_people: true)
        |> Enum.map(&Cases.preload_lab_results/1)

      assert person_1.lab_results |> tids() == ~w{person-1-result-1 person-1-result-2}
      assert person_2.lab_results |> tids() == ~w{person-2-result-2}

      lab_result = person_1.lab_results |> Enum.at(1)

      assert_revision_count(lab_result, 2)

      assert_recent_audit_log(lab_result, creator, %{
        "person_id" => person_1.id,
        "request_accession_number" => "accession-result-2",
        "request_facility_code" => "facility-result-2",
        "request_facility_name" => "result-2 Lab, Inc.",
        "result" => "positive",
        "sampled_on" => "2020-01-01",
        "tid" => "person-1-result-2-dupe"
      })
    end
  end

  describe "people" do
    test "archive_person archives a person and writes to audit log" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()

      {:ok, person} = Cases.archive_person(person.id, user, Test.Fixtures.admin_audit_meta())
      assert person.archived_by_id == user.id
      assert_recent(person.archived_at)
      assert_revision_count(person, 2)

      audit_log = recent_audit_log(person)
      assert audit_log.author_id == @admin.id
      {:ok, archived_at, _} = audit_log.change["archived_at"] |> DateTime.from_iso8601()
      assert_recent(archived_at)
      assert audit_log.change["archived_by_id"] == user.id
    end

    test "create_person! creates a person" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!() |> Cases.preload_demographics()

      assert person.tid == "alice"
      [person_demographics] = person.demographics
      assert person_demographics.dob == ~D[2000-01-01]
      assert person_demographics.first_name == "Alice"
      assert person_demographics.last_name == "Testuser"

      assert_revision_count(person, 1)

      assert %{
               "demographics" => [
                 %{
                   "dob" => "2000-01-01",
                   "first_name" => "Alice",
                   "last_name" => "Testuser",
                   "preferred_language" => "English"
                 }
               ],
               "tid" => "alice"
             } = recent_audit_log(person).change
    end

    test "create_person creates a person" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person()

      assert_revision_count(person, 1)
      assert Cases.get_person(person.id, @admin)

      assert %{
               "demographics" => [
                 %{
                   "dob" => "2000-01-01",
                   "first_name" => "Alice",
                   "last_name" => "Testuser",
                   "preferred_language" => "English"
                 }
               ],
               "tid" => "alice"
             } = recent_audit_log(person).change
    end

    test "create_person accepts a form demographic field" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      remove_demographics_list = fn {params, audit_meta} -> {params |> Map.delete(:demographics), audit_meta} end
      add_form_demographic = fn {params, audit_meta}, form_demographic -> {params |> Map.put(:form_demographic, form_demographic), audit_meta} end

      {:ok, person} =
        Test.Fixtures.person_attrs(user, "alice")
        |> remove_demographics_list.()
        |> add_form_demographic.(%{
          "dob" => "2000-01-01",
          "first_name" => "Alice",
          "last_name" => "Testuser",
          "preferred_language" => "English"
        })
        |> Cases.create_person()

      assert Cases.get_person(person.id, @admin)

      assert_revision_count(person, 1)

      assert %{
               "demographics" => [
                 %{
                   "dob" => "2000-01-01",
                   "first_name" => "Alice",
                   "last_name" => "Testuser",
                   "preferred_language" => "English"
                 }
               ],
               "tid" => "alice"
             } = recent_audit_log(person).change
    end

    test "duplicates" do
      [alice, amy, _billy] =
        [{"alice", "Alice", "Testuser1"}, {"amy", "Amy", "Testuser1"}, {"billy", "Billy", "Testuser2"}]
        |> Enum.map(fn {tid, first, last} ->
          Test.Fixtures.person_attrs(@admin, tid, %{})
          |> Test.Fixtures.add_demographic_attrs(%{first_name: first, last_name: last})
          |> Cases.create_person!()
        end)

      AuditLogAssertions.expect_phi_view_logs(1)
      assert Cases.list_duplicate_people(alice, @admin) |> tids() == ["amy"]
      AuditLogAssertions.verify_phi_view_logged(@admin, amy)
    end

    test "counting duplicate people does not audit-log views" do
      [alice, _amy, _billy] =
        [{"alice", "Alice", "Testuser1"}, {"amy", "Amy", "Testuser1"}, {"billy", "Billy", "Testuser2"}]
        |> Enum.map(fn {tid, first, last} ->
          Test.Fixtures.person_attrs(@admin, tid, %{})
          |> Test.Fixtures.add_demographic_attrs(%{first_name: first, last_name: last})
          |> Cases.create_person!()
        end)

      AuditLogAssertions.expect_phi_view_logs(0)
      assert Cases.count_duplicate_people(alice) == 1
    end

    test "get_people fetches all the people" do
      alice = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()
      Test.Fixtures.person_attrs(@admin, "billy") |> Cases.create_person!()
      Cases.get_people([alice.id], @admin) |> tids() |> assert_eq(["alice"])
    end

    test "get_people records audit log for all the fetched people" do
      alice = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()
      billy = Test.Fixtures.person_attrs(@admin, "billy") |> Cases.create_person!()

      AuditLogAssertions.expect_phi_view_logs(2)
      Cases.get_people([alice.id, billy.id], @admin)
      AuditLogAssertions.verify_phi_view_logged(@admin, [alice, billy])
    end

    test "get_person fetches record" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      fetched = Cases.get_person(person.id, @admin)
      assert fetched.tid == "alice"
    end

    test "get_person records an audit log entry" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()

      AuditLogAssertions.expect_phi_view_logs(1)

      Cases.get_person(person.id, @admin)
      AuditLogAssertions.verify_phi_view_logged(@admin, person)
    end
  end

  describe "list_people" do
    setup do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

      alice =
        Test.Fixtures.person_attrs(user, "alice", dob: ~D[2000-06-01], first_name: "Alice", last_name: "Testuser")
        |> Cases.create_person!()

      alice
      |> Test.Fixtures.lab_result_attrs(user, "alice-1", ~D[2020-06-02])
      |> Cases.create_lab_result!()

      alice = alice |> Cases.preload_lab_results()

      Test.Fixtures.case_investigation_attrs(alice, LabResult.latest(alice.lab_results), user, "pending-interview")
      |> Cases.create_case_investigation!()

      billy =
        Test.Fixtures.person_attrs(user, "billy", dob: ~D[2000-06-01], first_name: "Billy", last_name: "Testuser")
        |> Cases.create_person!()

      billy
      |> Test.Fixtures.lab_result_attrs(user, "billy-1", ~D[2020-06-03], %{result: "detected"})
      |> Cases.create_lab_result!()

      billy = billy |> Cases.preload_lab_results()

      Test.Fixtures.case_investigation_attrs(billy, LabResult.latest(billy.lab_results), user, "ongoing-interview", %{
        interview_started_at: ~U[2020-10-31 23:03:07Z]
      })
      |> Cases.create_case_investigation!()

      cindy =
        Test.Fixtures.person_attrs(user, "cindy", dob: ~D[2000-07-01], first_name: "Cindy", last_name: "Testuser")
        |> Cases.create_person!()

      Test.Fixtures.lab_result_attrs(cindy, user, "cindy-1", Extra.Date.days_ago(4))
      |> Cases.create_lab_result!()

      cindy = cindy |> Cases.preload_lab_results()

      Test.Fixtures.case_investigation_attrs(cindy, LabResult.latest(cindy.lab_results), user, "concluded-monitoring", %{
        interview_completed_at: ~U[2020-10-31 23:03:07Z],
        isolation_monitoring_starts_on: ~D[2020-11-03],
        isolation_monitoring_ends_on: ~D[2020-11-13],
        isolation_concluded_at: ~U[2020-10-31 10:30:00Z]
      })
      |> Cases.create_case_investigation!()

      david = Test.Fixtures.person_attrs(user, "david") |> Test.Fixtures.add_demographic_attrs(%{external_id: "david-id"}) |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(david, user, "david-result-1", Extra.Date.days_ago(3), result: "positive") |> Cases.create_lab_result!()

      david = david |> Cases.preload_lab_results()

      Test.Fixtures.case_investigation_attrs(david, LabResult.latest(david.lab_results), user, "ongoing-monitoring", %{
        interview_started_at: ~U[2020-10-31 22:03:07Z],
        interview_completed_at: ~U[2020-10-31 23:03:07Z],
        isolation_monitoring_starts_on: ~D[2020-11-03],
        isolation_monitoring_ends_on: ~D[2020-11-13]
      })
      |> Cases.create_case_investigation!()

      emily = Test.Fixtures.person_attrs(user, "emily") |> Test.Fixtures.add_demographic_attrs(%{external_id: "nancy-id"}) |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(emily, user, "emily-result-1", Extra.Date.days_ago(3), result: "positive") |> Cases.create_lab_result!()

      emily = emily |> Cases.preload_lab_results()

      Test.Fixtures.case_investigation_attrs(emily, LabResult.latest(emily.lab_results), user, "pending-monitoring", %{
        interview_started_at: ~U[2020-10-31 22:03:07Z],
        interview_completed_at: ~U[2020-10-31 23:03:07Z]
      })
      |> Cases.create_case_investigation!()

      nancy =
        Test.Fixtures.person_attrs(user, "nancy", dob: ~D[2000-06-01], first_name: "Nancy", last_name: "Testuser")
        |> Cases.create_person!()

      nancy
      |> Test.Fixtures.lab_result_attrs(user, "nancy-1", ~D[2020-06-03], %{result: "negative"})
      |> Cases.create_lab_result!()

      {:ok, _} =
        Cases.assign_user_to_people(
          user_id: user.id,
          people_ids: [alice.id, billy.id, emily.id, nancy.id],
          audit_meta: Test.Fixtures.admin_audit_meta(),
          current_user: @admin
        )

      [alice: alice, billy: billy, cindy: cindy, david: david, emily: emily, nancy: nancy, user: user]
    end

    test "all", %{user: user} do
      Cases.list_people(:all, user: @admin, reject_archived_people: true) |> tids() |> assert_eq(~w{alice billy cindy david emily nancy})
      Cases.list_people(:all, assigned_to_id: user.id, user: @admin, reject_archived_people: true) |> tids() |> assert_eq(~w{alice billy emily nancy})
    end

    test "records audit log for viewed people", context do
      AuditLogAssertions.expect_phi_view_logs(6)

      Cases.list_people(:all, user: @admin, reject_archived_people: true)
      AuditLogAssertions.verify_phi_view_logged(@admin, [context.alice, context.billy, context.cindy, context.david, context.emily, context.nancy])
    end
  end

  test "assign_user_to_people updates people's assigned user" do
    creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
    updater = Test.Fixtures.user_attrs(@admin, "updater") |> Accounts.register_user!()

    assigned_to_user = Test.Fixtures.user_attrs(@admin, "assigned-to") |> Accounts.register_user!()
    alice = Test.Fixtures.person_attrs(creator, "alice") |> Cases.create_person!()
    bobby = Test.Fixtures.person_attrs(creator, "bobby") |> Cases.create_person!()

    {:ok, [updated_alice]} =
      Cases.assign_user_to_people(
        user_id: assigned_to_user.id,
        people_ids: [alice.id],
        audit_meta: Test.Fixtures.audit_meta(updater),
        current_user: @admin
      )

    assert updated_alice |> Repo.preload(:assigned_to) |> Map.get(:assigned_to) |> Map.get(:tid) == "assigned-to"
    assert updated_alice.assigned_to.tid == "assigned-to"

    assert_revision_count(updated_alice, 2)

    assert_recent_audit_log(
      updated_alice,
      updater,
      %{"assigned_to_id" => assigned_to_user.id}
    )

    assert bobby |> Repo.preload(:assigned_to) |> Map.get(:assigned_to) == nil
  end

  test "update_person updates a person" do
    user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()

    person =
      Test.Fixtures.person_attrs(user, "versioned") |> Test.Fixtures.add_demographic_attrs(%{first_name: "version-1"}) |> Cases.create_person!()

    [%{id: demographic_id}] = person.demographics

    {:ok, updated_person} =
      person |> Cases.update_person({%{demographics: [%{id: demographic_id, first_name: "version-2"}]}, Test.Fixtures.audit_meta(user)})

    updated_person = updated_person |> Cases.preload_demographics()
    assert Person.coalesce_demographics(updated_person).first_name == "version-2"

    assert_revision_count(person, 2)

    assert %{
             "demographics" => [
               %{
                 "id" => ^demographic_id,
                 "first_name" => "version-2"
               }
             ]
           } = recent_audit_log(person).change
  end

  test "update_person accepts form_demographic" do
    {:ok, _} =
      %{
        file_name: "test.csv",
        contents: """
        search_firstname_2 , search_lastname_1 , dateofbirth_8 , datecollected_36 , resultdate_42 , result_39 , person_tid
        Alice              , Testuser          , 01/01/1970    , 06/01/2020       , 06/03/2020    , positive  , alice
        """
      }
      |> Cases.import_lab_results(@admin)

    [alice] = Cases.list_people(:all, user: @admin, reject_archived_people: true) |> Cases.preload_demographics()

    {:ok, _} =
      Cases.update_person(
        alice,
        {%{
           form_demographic: %{
             "dob" => "2000-02-01",
             "first_name" => "Ally",
             "last_name" => "Testuser",
             "preferred_language" => "English"
           }
         }, Test.Fixtures.admin_audit_meta()}
      )

    assert %{
             demographics: [
               %{source: "import", first_name: "Alice"},
               %{source: "form", first_name: "Ally"}
             ]
           } = Cases.get_person(alice.id, @admin) |> Cases.preload_demographics()
  end

  test "find_matching_person finds a person by their dob, first_name, and last_name" do
    dob = ~D[2000-01-01]
    strip_seq = fn map -> Map.put(map, :seq, nil) end
    person = Test.Fixtures.person_attrs(@admin, "alice", dob: dob) |> Cases.create_person!() |> strip_seq.()

    match = Cases.find_matching_person(%{"first_name" => "Alice", "last_name" => "Testuser", "dob" => dob})

    assert match.id == person.id

    refute Cases.find_matching_person(%{"first_name" => "billy", "last_name" => "Testuser", "dob" => dob})
    refute Cases.find_matching_person(%{"first_name" => "Alice", "last_name" => "Testy", "dob" => dob})
    refute Cases.find_matching_person(%{"first_name" => "Alice", "last_name" => "Testuser", "dob" => ~D[2000-01-02]})
  end

  test "find_matching_person finds a person with their dob, first_name, and last_name spread accross three records" do
    dob = ~D[2000-01-01]

    person =
      Test.Fixtures.person_attrs(@admin, "alice")
      |> (fn {attrs, meta} -> {Map.put(attrs, :demographics, [%{first_name: "Firsty"}, %{last_name: "Testuser"}, %{dob: dob}]), meta} end).()
      |> Cases.create_person!()

    match = Cases.find_matching_person(%{"first_name" => "Firsty", "last_name" => "Testuser", "dob" => dob})

    assert match.id == person.id

    refute Cases.find_matching_person(%{"first_name" => "billy", "last_name" => "Testuser", "dob" => dob})
    refute Cases.find_matching_person(%{"first_name" => "Firsty", "last_name" => "Testy", "dob" => dob})
    refute Cases.find_matching_person(%{"first_name" => "Firsty", "last_name" => "Testuser", "dob" => ~D[2000-01-02]})
  end

  test "create_demographic/2" do
    person = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()

    {:ok, demo1} =
      Cases.create_demographic({Test.Fixtures.add_demographic_attrs(%{tid: "second", person_id: person.id}), Test.Fixtures.audit_meta(@admin)})

    {:ok, demo2} =
      Cases.create_demographic({Test.Fixtures.add_demographic_attrs(%{tid: "third", person_id: person.id}), Test.Fixtures.audit_meta(@admin)})

    assert Cases.get_person(person.id, @admin)
           |> Cases.preload_demographics()
           |> Map.get(:demographics)
           |> length() == 3

    assert %{change: %{"tid" => "second"}} = recent_audit_log(demo1)
    assert %{change: %{"tid" => "third"}} = recent_audit_log(demo2)
  end

  describe "create_phone!" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()

      %{creator: creator, person: person}
    end

    test "persists the values correctly", %{person: person, creator: creator} do
      phone = Test.Fixtures.phone_attrs(creator, person, "phone1", %{}) |> Cases.create_phone!()

      assert phone.number == "1111111000"
      assert phone.person_id == person.id
      assert phone.type == "home"
      assert phone.tid == "phone1"
    end

    test "has a revision count", %{person: person, creator: creator} do
      phone = Test.Fixtures.phone_attrs(creator, person, "phone1", %{}) |> Cases.create_phone!()

      assert_revision_count(phone, 1)
    end

    test "has an audit log", %{person: person, creator: creator} do
      phone = Test.Fixtures.phone_attrs(creator, person, "phone1", %{}) |> Cases.create_phone!()

      assert_recent_audit_log(phone, creator, %{
        "tid" => "phone1",
        "number" => "1111111000",
        "person_id" => person.id,
        "type" => "home"
      })
    end
  end

  describe "upsert_phone!" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()

      %{creator: creator, person: person}
    end

    defp add_phone_for_person(tid, person, creator) do
      original_phone = Test.Fixtures.phone_attrs(creator, person, tid, %{}) |> Cases.create_phone!()
      {:ok, sql_safe_id} = Ecto.UUID.dump(original_phone.id)

      Ecto.Adapters.SQL.query!(
        EpiViewpoint.Repo,
        "UPDATE phones SET updated_at = $1 WHERE id = $2",
        [~U[1970-01-01 10:30:00Z], sql_safe_id]
      )

      original_phone
    end

    test "when the phone number already exists for the same person", %{person: person, creator: creator} do
      original_phone = add_phone_for_person("phone1", person, creator)

      assert Cases.get_phone(original_phone.id).updated_at == ~U[1970-01-01 10:30:00Z]

      phone = Test.Fixtures.phone_attrs(creator, person, "phone2", %{number: original_phone.number}) |> Cases.upsert_phone!()

      person = Cases.preload_phones(person)
      assert person.phones |> tids == ["phone1"]
      assert person.phones |> pluck(:updated_at) != ~N[1970-01-01 10:30:00Z]

      assert_revision_count(phone, 2)

      assert_recent_audit_log(phone, creator, %{
        "tid" => "phone2",
        "number" => "1111111000",
        "person_id" => person.id,
        "type" => "home"
      })
    end

    test "when the phone number already exists for a different person", %{creator: creator, person: person} do
      {:ok, other_person} = Test.Fixtures.person_attrs(creator, "person2") |> Cases.create_person()
      other_persons_phone = add_phone_for_person("phone3", other_person, creator)

      phone = Test.Fixtures.phone_attrs(creator, person, "phone2", %{number: other_persons_phone.number}) |> Cases.upsert_phone!()

      other_person = Cases.preload_phones(other_person)
      assert other_person.phones |> tids == ["phone3"]
      person = Cases.preload_phones(person)
      assert person.phones |> tids == ["phone2"]

      assert_revision_count(phone, 1)

      assert_recent_audit_log(phone, creator, %{
        "tid" => "phone2",
        "number" => "1111111000",
        "person_id" => person.id,
        "type" => "home"
      })
    end

    test "when the phone number does not yet exist", %{creator: creator, person: person} do
      assert Cases.preload_phones(person).phones == []
      phone = Test.Fixtures.phone_attrs(creator, person, "phone2", %{}) |> Cases.upsert_phone!()

      person = Cases.preload_phones(person)
      assert person.phones |> tids == ["phone2"]

      assert_revision_count(phone, 1)

      assert_recent_audit_log(phone, creator, %{
        "tid" => "phone2",
        "number" => "1111111000",
        "person_id" => person.id,
        "type" => "home"
      })
    end
  end

  describe "create_address!" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()
      audit_meta = Test.Fixtures.audit_meta(creator)

      %{creator: creator, person: person, audit_meta: audit_meta}
    end

    test "persists the values correctly", %{creator: creator, person: person} do
      address = Test.Fixtures.address_attrs(creator, person, "address1", 4250) |> Cases.create_address!()

      assert address.street == "4250 Test St"
      assert address.city == "City"
      assert address.state == "OH"
      assert address.postal_code == "00000"
      assert address.type == "home"
      assert address.tid == "address1"
      assert address.person_id == person.id
    end

    test "has a revision count", %{creator: creator, person: person} do
      address = Test.Fixtures.address_attrs(creator, person, "address1", 4250) |> Cases.create_address!()

      assert_revision_count(address, 1)
    end

    test "has an audit log", %{creator: creator, person: person} do
      address = Test.Fixtures.address_attrs(creator, person, "address1", 4250) |> Cases.create_address!()

      assert_recent_audit_log(address, creator, %{
        "tid" => "address1",
        "street" => "4250 Test St",
        "city" => "City",
        "state" => "OH",
        "postal_code" => "00000",
        "person_id" => person.id,
        "type" => "home"
      })
    end
  end

  describe "upsert_address!" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()
      audit_meta = Test.Fixtures.audit_meta(creator)

      %{creator: creator, person: person, audit_meta: audit_meta}
    end

    test "when the address already exists for the same person", %{creator: creator, person: person, audit_meta: audit_meta} do
      original_address = Test.Fixtures.address_attrs(creator, person, "address1", 4250) |> Cases.create_address!()

      {:ok, sql_safe_id} = Ecto.UUID.dump(original_address.id)
      Ecto.Adapters.SQL.query!(EpiViewpoint.Repo, "UPDATE addresses SET updated_at = $1 WHERE id = $2", [~N[1970-01-01 10:30:00Z], sql_safe_id])

      Cases.upsert_address!({Map.from_struct(%{original_address | tid: "address2"}), audit_meta})

      %Cases.Person{addresses: addresses} = Cases.preload_addresses(person)
      assert length(addresses) == 1
      assert hd(addresses).updated_at != ~N[1970-01-01 10:30:00Z]

      assert_revision_count(original_address, 2)

      assert_recent_audit_log(original_address, creator, %{
        "tid" => "address2",
        "street" => "4250 Test St",
        "city" => "City",
        "state" => "OH",
        "postal_code" => "00000",
        "person_id" => person.id,
        "type" => "home"
      })
    end

    test "when the address already exists for a different person", %{creator: creator, person: person, audit_meta: audit_meta} do
      {:ok, other_person} = Test.Fixtures.person_attrs(creator, "other person") |> Cases.create_person()
      original_address = Test.Fixtures.address_attrs(creator, other_person, "other address", 4250) |> Cases.create_address!()

      new_address = Cases.upsert_address!({Map.from_struct(%{original_address | tid: "address2", person_id: person.id}), audit_meta})

      %Cases.Person{addresses: addresses} = Cases.preload_addresses(person)
      assert hd(addresses).tid == "address2"

      %Cases.Person{addresses: addresses} = Cases.preload_addresses(other_person)
      assert hd(addresses).tid == "other address"

      assert_revision_count(new_address, 1)

      assert_recent_audit_log(new_address, creator, %{
        "tid" => "address2",
        "street" => "4250 Test St",
        "city" => "City",
        "state" => "OH",
        "postal_code" => "00000",
        "person_id" => person.id,
        "type" => "home"
      })
    end

    test "when the address does not yet exist", %{person: person, creator: creator} do
      new_address = Cases.upsert_address!(Test.Fixtures.address_attrs(creator, person, "address1", 4250))

      %Cases.Person{addresses: addresses} = Cases.preload_addresses(person)
      assert length(addresses) == 1
      assert hd(addresses).tid == "address1"

      assert_revision_count(new_address, 1)

      assert_recent_audit_log(new_address, creator, %{
        "tid" => "address1",
        "street" => "4250 Test St",
        "city" => "City",
        "state" => "OH",
        "postal_code" => "00000",
        "person_id" => person.id,
        "type" => "home"
      })
    end
  end

  describe "get_case_investigation" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()
      lab_result = Test.Fixtures.lab_result_attrs(person, creator, "person1_test_result", ~D[2020-10-04]) |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(person, lab_result, creator, "fixture_case_investigation", %{name: "the name"})
        |> Cases.create_case_investigation!()

      [case_investigation: case_investigation]
    end

    test "returns the case investigation", %{case_investigation: case_investigation} do
      fetched_case_investigation = Cases.get_case_investigation(case_investigation.id, @admin)

      assert fetched_case_investigation.tid == case_investigation.tid
    end

    test "records an audit log entry", %{case_investigation: case_investigation} do
      case_investigation = case_investigation |> Cases.preload_person()
      AuditLogAssertions.expect_phi_view_logs(1)
      Cases.get_case_investigation(case_investigation.id, @admin)
      AuditLogAssertions.verify_phi_view_logged(@admin, case_investigation.person)
    end
  end

  describe "create_case_investigation!" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()
      audit_meta = Test.Fixtures.audit_meta(creator)
      lab_result = Test.Fixtures.lab_result_attrs(person, creator, "person1_test_result", ~D[2020-10-04]) |> Cases.create_lab_result!()

      %{creator: creator, person: person, audit_meta: audit_meta, lab_result: lab_result}
    end

    test "makes a revision", %{person: person, lab_result: lab_result, creator: creator} do
      case_investigation =
        Test.Fixtures.case_investigation_attrs(person, lab_result, creator, "person1_case_investigation", %{name: "the name"})
        |> Cases.create_case_investigation!()

      author_id = creator.id
      lab_result_id = lab_result.id

      assert %{author_id: ^author_id, change: %{"initiating_lab_result_id" => ^lab_result_id, "name" => "the name"}} =
               recent_audit_log(case_investigation)
    end
  end

  describe "create_investigation_note!" do
    setup do
      creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
      {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()
      audit_meta = Test.Fixtures.audit_meta(creator)
      lab_result = Test.Fixtures.lab_result_attrs(person, creator, "person1_test_result", ~D[2020-10-04]) |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(person, lab_result, creator, "person1_case_investigation", %{})
        |> Cases.create_case_investigation!()

      %{creator: creator, person: person, audit_meta: audit_meta, case_investigation: case_investigation}
    end

    test "makes a revision", %{creator: creator, case_investigation: case_investigation} do
      case_investigation_note =
        Test.Fixtures.case_investigation_note_attrs(case_investigation, creator, "note-a", %{text: "Note A"})
        |> Cases.create_investigation_note!()

      author_id = creator.id
      case_investigation_id = case_investigation.id

      assert %{author_id: ^author_id, change: %{"case_investigation_id" => ^case_investigation_id, "text" => "Note A"}} =
               recent_audit_log(case_investigation_note)
    end
  end

  describe "create_contact_investigation" do
    setup :create_multiple_case_and_contact_investigations

    test "makes an contact_investigation and a revision", %{case_investigation: case_investigation, contact_investigation: contact_investigation} do
      fetched_contact_investigation = ContactInvestigations.get(contact_investigation.id, @admin)
      assert fetched_contact_investigation.exposing_case_id == case_investigation.id
      assert_revision_count(contact_investigation, 1)
    end
  end

  describe "update_contact_investigation" do
    setup :create_multiple_case_and_contact_investigations

    test "updates an contact_investigation end creates a revision", %{contact_investigation: contact_investigation} do
      {:ok, contact_investigation} =
        ContactInvestigations.update(contact_investigation, {
          %{household_member: true},
          Test.Fixtures.admin_audit_meta()
        })

      author_id = @admin.id
      assert %{household_member: true} = ContactInvestigations.get(contact_investigation.id, Test.Fixtures.admin())
      assert %{author_id: ^author_id, change: %{"household_member" => true}} = recent_audit_log(contact_investigation)
    end
  end

  describe "preload_contact_investigations" do
    alias EpiViewpoint.Cases.Merge

    setup :create_multiple_case_and_contact_investigations

    test "hydrates exactly into an contact_investigation's exposed_person's demographics and phones", %{case_investigation: case_investigation} do
      assert %{
               contact_investigations: [
                 %{
                   exposed_person: %{
                     demographics: [
                       %{first_name: "Cindy"}
                     ],
                     phones: [
                       %{number: "1111111987"}
                     ]
                   }
                 }
               ]
             } = Cases.get_case_investigation(case_investigation.id, @admin) |> Cases.preload_contact_investigations(@admin)
    end

    test "records an audit log entry for each contact investigation", %{
      case_investigation: case_investigation,
      contact_investigation: contact_investigation
    } do
      AuditLogAssertions.expect_phi_view_logs(2)
      Cases.get_case_investigation(case_investigation.id, @admin) |> Cases.preload_contact_investigations(@admin)
      AuditLogAssertions.verify_phi_view_logged(@admin, contact_investigation.exposed_person)
    end

    test "records an audit log entry for each contact investigation of each case investigation", %{
      case_investigation: case_investigation,
      contact_investigation: contact_investigation,
      other_case_investigation: other_case_investigation,
      other_contact_investigation: other_contact_investigation
    } do
      AuditLogAssertions.expect_phi_view_logs(2)

      [case_investigation, other_case_investigation]
      |> Cases.preload_contact_investigations(@admin)

      AuditLogAssertions.verify_phi_view_logged(@admin, [contact_investigation.exposed_person, other_contact_investigation.exposed_person])
    end

    test "does not record an audit log entry when the case investigation is nil" do
      AuditLogAssertions.expect_phi_view_logs(0)
      Cases.preload_contact_investigations(nil, @admin)
    end

    test "merging a contact investigation's exposed person into another causes the canonical person to be logged instead", %{
      case_investigation: case_investigation,
      contact_investigation: contact_investigation
    } do
      {:ok, %{exposed_person: duplicate_person}} = create_contact_investigation(case_investigation, "Merged", "1111111234")
      canonical_person = Test.Fixtures.person_attrs(@admin, "canonical-person") |> Cases.create_person!()

      Merge.merge([duplicate_person.id], into: canonical_person.id, merge_conflict_resolutions: %{}, current_user: @admin)

      AuditLogAssertions.expect_phi_view_logs(2)
      [case_investigation] |> Cases.preload_contact_investigations(@admin)
      AuditLogAssertions.verify_phi_view_logged(@admin, [contact_investigation.exposed_person, canonical_person], match: :exact)
    end
  end

  describe "preload_exposed_person" do
    setup :create_multiple_case_and_contact_investigations

    test "hydrates exactly into the exposed_person's demographics and phones", %{contact_investigation: contact_investigation} do
      assert %{
               exposed_person: %{
                 demographics: [
                   %{first_name: "Cindy"}
                 ],
                 phones: [
                   %{number: "1111111987"}
                 ]
               }
             } = ContactInvestigations.get(contact_investigation.id, @admin) |> ContactInvestigations.preload_exposed_person()
    end
  end

  describe "places" do
    test "list_places" do
      {:ok, _} = Test.Fixtures.place_attrs(@admin, "place-1") |> Cases.create_place()
      {:ok, _} = Test.Fixtures.place_attrs(@admin, "place-2") |> Cases.create_place()

      Cases.list_places(@admin) |> tids() |> assert_eq(~w[place-1 place-2], ignore_order: true)
    end

    test "create_place with place address" do
      {place_attrs, _} = Test.Fixtures.place_attrs(@admin, "place", place_addresses: [%{street: "3456 Test St", tid: "place-address"}])
      {:ok, place} = Cases.create_place({place_attrs, Test.Fixtures.admin_audit_meta()})

      place = place |> Cases.preload_place_addresses()

      assert place.tid == "place"
      place.place_addresses |> tids() |> assert_eq(~w[place-address])
    end
  end

  # # #

  defp create_contact_investigation(case_investigation, first_name, phone_number) do
    ContactInvestigations.create({
      Test.Fixtures.contact_investigation_attrs("contact_investigation", %{exposing_case_id: case_investigation.id})
      |> Map.put(:exposed_person, %{
        demographics: [
          %{first_name: first_name}
        ],
        phones: [
          %{number: phone_number}
        ]
      }),
      Test.Fixtures.admin_audit_meta()
    })
  end

  defp create_multiple_case_and_contact_investigations(_context) do
    creator = Test.Fixtures.user_attrs(@admin, "creator") |> Accounts.register_user!()
    {:ok, person} = Test.Fixtures.person_attrs(creator, "person1") |> Cases.create_person()
    lab_result = Test.Fixtures.lab_result_attrs(person, creator, "person1_test_result", ~D[2020-10-04]) |> Cases.create_lab_result!()

    case_investigation =
      Test.Fixtures.case_investigation_attrs(person, lab_result, creator, "person1_case_investigation", %{})
      |> Cases.create_case_investigation!()

    {:ok, contact_investigation} = create_contact_investigation(case_investigation, "Cindy", "1111111987")

    other_case_investigation =
      Test.Fixtures.case_investigation_attrs(person, lab_result, creator, "person1_case_investigation", %{})
      |> Cases.create_case_investigation!()

    {:ok, other_contact_investigation} = create_contact_investigation(other_case_investigation, "Cindy", "1111111987")

    [
      case_investigation: case_investigation,
      contact_investigation: contact_investigation,
      other_case_investigation: other_case_investigation,
      other_contact_investigation: other_contact_investigation
    ]
  end
end
