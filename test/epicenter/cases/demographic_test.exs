defmodule Epicenter.Cases.DemographicTest do
  use Epicenter.DataCase, async: true

  import Euclid.Extra.Enum, only: [tids: 1]

  alias Epicenter.Cases
  alias Epicenter.Cases.Demographic
  alias Epicenter.Test

  describe "schema" do
    test "fields" do
      assert_schema(
        Demographic,
        [
          {:dob, :date},
          {:employment, :string},
          {:ethnicity, :map},
          {:external_id, :string},
          {:first_name, :string},
          {:gender_identity, {:array, :string}},
          {:id, :binary_id},
          {:inserted_at, :utc_datetime},
          {:last_name, :string},
          {:marital_status, :string},
          {:notes, :string},
          {:occupation, :string},
          {:person_id, :binary_id},
          {:preferred_language, :string},
          {:race, :string},
          {:seq, :integer},
          {:sex_at_birth, :string},
          {:source, :string},
          {:tid, :string},
          {:updated_at, :utc_datetime}
        ]
      )
    end
  end

  describe "validation" do
    defp new_changeset(attr_updates) do
      Demographic.changeset(%Demographic{}, attr_updates)
    end

    test "validates personal health information on dob", do: assert_invalid(new_changeset(%{dob: "01-10-2000"}))
    test "validates personal health information on last_name", do: assert_invalid(new_changeset(%{last_name: "Aliceblat"}))
  end

  describe "ethnicity" do
    test "is embedded" do
      attrs = %{
        dob: ~D[2020-01-01],
        first_name: "Alice",
        last_name: "Testuser",
        ethnicity: %{major: "major", detailed: ["detailed1", "detailed2"]}
      }

      ethnicity_changeset = Demographic.changeset(%Demographic{}, attrs) |> Ecto.Changeset.get_change(:ethnicity)
      ethnicity_changeset |> Ecto.Changeset.get_change(:major) |> assert_eq("major")
      ethnicity_changeset |> Ecto.Changeset.get_change(:detailed) |> assert_eq(["detailed1", "detailed2"])
    end
  end

  describe "find_humanized_value" do
    test "gets humanized values for fields" do
      assert Demographic.find_humanized_value(:gender_identity, "male") == "Male"
      assert Demographic.find_humanized_value(:gender_identity, "abcdef") == "abcdef"
      assert Demographic.find_humanized_value(:bogus_field, "abcdef") == "abcdef"
    end
  end

  describe "Query.display_order" do
    test "sorts by insertion order" do
      author = Test.Fixtures.admin()
      {:ok, person} = Test.Fixtures.person_attrs(author, "person") |> Cases.create_person()
      {:ok, _} = Test.Fixtures.demographic_attrs(author, person, "first") |> Cases.create_demographic()
      {:ok, _} = Test.Fixtures.demographic_attrs(author, person, "second") |> Cases.create_demographic()
      {:ok, _} = Test.Fixtures.demographic_attrs(author, person, "third") |> Cases.create_demographic()

      Demographic.Query.display_order() |> Repo.all() |> tids() |> assert_eq([nil, "first", "second", "third"])
    end
  end

  describe "Query.latest_form_demographic" do
    setup do
      author = Test.Fixtures.admin()
      {:ok, person} = Test.Fixtures.person_attrs(author, "person", %{}, demographics: false) |> Cases.create_person()
      [author: author, person: person]
    end

    test "returns nil when the person has no demographics", %{person: person} do
      assert Demographic.Query.latest_form_demographic(person) |> Repo.one() == nil
    end

    test "returns nil when the person has only demographics from an import", %{author: author, person: person} do
      {:ok, _} = Test.Fixtures.demographic_attrs(author, person, "import", source: "import") |> Cases.create_demographic()
      assert Demographic.Query.latest_form_demographic(person) |> Repo.one() == nil
    end

    test "returns the latest form demographic when the person has demographics from a form", %{author: author, person: person} do
      {:ok, _} = Test.Fixtures.demographic_attrs(author, person, "import", source: "import") |> Cases.create_demographic()
      {:ok, _} = Test.Fixtures.demographic_attrs(author, person, "form1", source: "form") |> Cases.create_demographic()
      {:ok, _} = Test.Fixtures.demographic_attrs(author, person, "form2", source: "form") |> Cases.create_demographic()
      {:ok, _} = Test.Fixtures.demographic_attrs(author, person, "form3", source: "form") |> Cases.create_demographic()
      assert %Demographic{tid: "form3", source: "form"} = Demographic.Query.latest_form_demographic(person) |> Repo.one()
    end
  end
end
