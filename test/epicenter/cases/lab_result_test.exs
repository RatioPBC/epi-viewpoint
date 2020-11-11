defmodule Epicenter.Cases.LabResultTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.Cases.LabResult
  alias Epicenter.Test

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

  describe "positive?" do
    setup do
      user = Test.Fixtures.user_attrs(@admin, "user") |> Accounts.register_user!()
      person = Test.Fixtures.person_attrs(user, "alice") |> Cases.create_person!()
      [user: user, person: person]
    end

    test "when result is a case-insensitive match of positive, returns true", %{user: user, person: person} do
      lab_result = Test.Fixtures.lab_result_attrs(person, user, "result-1", "06-02-2020", result: "positive") |> Cases.create_lab_result!()
      assert LabResult.positive?(lab_result)

      lab_result = Test.Fixtures.lab_result_attrs(person, user, "result-2", "06-02-2020", result: "pOsItIvE") |> Cases.create_lab_result!()
      assert LabResult.positive?(lab_result)
    end

    test "when result is a case-insensitive match of other, returns true", %{user: user, person: person} do
      lab_result = Test.Fixtures.lab_result_attrs(person, user, "result-1", "06-02-2020", result: "other") |> Cases.create_lab_result!()
      assert LabResult.positive?(lab_result)

      lab_result = Test.Fixtures.lab_result_attrs(person, user, "result-2", "06-02-2020", result: "oThEr") |> Cases.create_lab_result!()
      assert LabResult.positive?(lab_result)
    end

    test "when result is anything else, returns false", %{user: user, person: person} do
      lab_result = Test.Fixtures.lab_result_attrs(person, user, "result-1", "06-02-2020", result: "negative") |> Cases.create_lab_result!()
      refute LabResult.positive?(lab_result)

      lab_result = Test.Fixtures.lab_result_attrs(person, user, "result-2", "06-02-2020", result: nil) |> Cases.create_lab_result!()
      refute LabResult.positive?(lab_result)
    end
  end
end
