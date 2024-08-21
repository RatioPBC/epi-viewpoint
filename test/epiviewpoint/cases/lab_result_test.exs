defmodule EpiViewpoint.Cases.LabResultTest do
  use EpiViewpoint.DataCase, async: true

  alias EpiViewpoint.Accounts
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.LabResult
  alias EpiViewpoint.Test

  setup :persist_admin
  @admin Test.Fixtures.admin()

  describe "schema" do
    test "fields" do
      assert_schema(
        LabResult,
        [
          {:analyzed_on, :date},
          {:fingerprint, :string},
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:is_positive_or_detected, :boolean},
          {:person_id, :binary_id},
          {:reported_on, :date},
          {:request_accession_number, :string},
          {:request_facility_code, :string},
          {:request_facility_name, :string},
          {:result, :string},
          {:sampled_on, :date},
          {:seq, :integer},
          {:source, :string},
          {:test_type, :string},
          {:tid, :string},
          {:updated_at, :utc_datetime}
        ]
      )
    end
  end

  describe "changeset" do
    defp new_changeset(attr_updates) do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      {default_attrs, _} = Test.Fixtures.lab_result_attrs(person, user, "result1", "06-01-2020")
      Cases.change_lab_result(%LabResult{}, Map.merge(default_attrs, attr_updates |> Enum.into(%{})))
    end

    test "default test attrs are valid", do: assert_valid(new_changeset(%{}))
    test "person_id is required", do: assert_invalid(new_changeset(person_id: nil))
    test "result is not required", do: assert_valid(new_changeset(result: nil))
    test "sample date is not required", do: assert_valid(new_changeset(sampled_on: nil))

    test "attributes" do
      changes =
        new_changeset(
          analyzed_on: ~D[2020-09-10],
          reported_on: ~D[2020-09-11],
          sampled_on: ~D[2020-09-12],
          result: "positive",
          test_type: "PCR",
          source: "form"
        ).changes

      assert changes.analyzed_on == ~D[2020-09-10]
      assert changes.reported_on == ~D[2020-09-11]
      assert changes.result == "positive"
      assert changes.source == "form"
      assert changes.test_type == "PCR"
    end
  end

  describe "fingerprint" do
    test "is generated based on field values" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      {attrs_1, _} = Test.Fixtures.lab_result_attrs(%Cases.Person{id: "1234567890"}, user, "result-1", "06-01-2020")
      fingerprint_1 = Cases.change_lab_result(%LabResult{}, attrs_1) |> LabResult.generate_fingerprint()

      assert fingerprint_1 == "79f75f4da6f2bda20cb3712509c0b80b428bcae87874cc7a2522de1d9714c116",
             """
             If this test starts failing, it might mean that fields were added to (or removed from)
             the fingerprint. If that happens, the fingerprint column in the table *MAY* not be useful
             for de-duplication anymore. One fix would be to create a second fingerprint column,
             backfill it, start using it for de-duplication, and then drop the original fingerprint column.
             """

      {attrs_2, _} = Test.Fixtures.lab_result_attrs(%Cases.Person{id: "0987654321"}, user, "result-2", "06-02-2020")
      fingerprint_2 = Cases.change_lab_result(%LabResult{}, attrs_2) |> LabResult.generate_fingerprint()
      assert fingerprint_2 == "62db806d0670342467c51af7d4049f8c7bf47504f07b8682ec405bf38eea17da"
    end
  end

  describe "is_positive_or_detected" do
    test "is true when the lab result is 'detected'" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person!()

      lab_result =
        Test.Fixtures.lab_result_attrs(person, user, "result-1", "06-01-2020", result: "dEtEctEd")
        |> Cases.create_lab_result!()

      assert lab_result.is_positive_or_detected
    end

    test "is true when the lab result is 'positive'" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person!()

      lab_result =
        Test.Fixtures.lab_result_attrs(person, user, "result-1", "06-01-2020", result: "pOsItIvE")
        |> Cases.create_lab_result!()

      assert lab_result.is_positive_or_detected
    end

    test "is false when the lab result is anything else" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person!()

      lab_result =
        Test.Fixtures.lab_result_attrs(person, user, "result-1", "06-01-2020", result: "negative")
        |> Cases.create_lab_result!()

      refute lab_result.is_positive_or_detected
    end
  end

  describe "latest" do
    setup do
      [user: Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()]
    end

    test "returns nil if no lab results", %{user: user} do
      person =
        user
        |> Test.Fixtures.person_attrs("alice")
        |> Cases.create_person!()
        |> Cases.preload_lab_results()

      LabResult.latest(person.lab_results) |> assert_eq(nil)
    end

    test "returns the lab result with the most recent sample date", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, user, "newer", "06-02-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, user, "older", "06-01-2020") |> Cases.create_lab_result!()

      alice = alice |> Cases.preload_lab_results()
      assert LabResult.latest(alice.lab_results).tid == "newer"
    end

    test "when there is a null sampled_on, returns that record first", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, user, "newer", "06-02-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, user, "older", "06-01-2020") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, user, "unknown", nil) |> Cases.create_lab_result!()

      alice = alice |> Cases.preload_lab_results()
      assert LabResult.latest(alice.lab_results).tid == "unknown"
    end

    test "when there are two records with null sampled_on, returns the lab results with the largest seq", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, user, "unknown", nil) |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, user, "newer unknown", nil) |> Cases.create_lab_result!()

      alice = alice |> Cases.preload_lab_results()
      assert LabResult.latest(alice.lab_results).tid == "newer unknown"
    end

    test "can filter positive only", %{user: user} do
      alice = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      Test.Fixtures.lab_result_attrs(alice, user, "alice-negative", "06-02-2020", result: "negative") |> Cases.create_lab_result!()
      Test.Fixtures.lab_result_attrs(alice, user, "alice-positive", "06-01-2020", result: "positive") |> Cases.create_lab_result!()

      alice = alice |> Cases.preload_lab_results()
      assert LabResult.latest(alice.lab_results, :positive).tid == "alice-positive"
    end
  end

  describe "query" do
    import Euclid.Extra.Enum, only: [tids: 1]

    test "display_order sorts by sampled_on with nulls first, then sampled_on values (desc), then by reported_on (desc)" do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()

      [
        Test.Fixtures.lab_result_attrs(person, user, "lab4", ~D[2020-04-13], reported_on: ~D[2020-04-26]),
        Test.Fixtures.lab_result_attrs(person, user, "lab1", ~D[2020-04-15], reported_on: ~D[2020-04-25]),
        Test.Fixtures.lab_result_attrs(person, user, "lab0", nil, reported_on: ~D[2020-04-25]),
        Test.Fixtures.lab_result_attrs(person, user, "lab3", ~D[2020-04-14], reported_on: ~D[2020-04-23]),
        Test.Fixtures.lab_result_attrs(person, user, "lab2", ~D[2020-04-14], reported_on: ~D[2020-04-24])
      ]
      |> Enum.each(&Cases.create_lab_result!/1)

      LabResult.Query.display_order() |> Repo.all() |> tids() |> assert_eq(~w{lab0 lab1 lab2 lab3 lab4})
    end
  end
end
