defmodule EpicenterWeb.DemographicsEditLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person =
      Test.Fixtures.person_attrs(user, "alice")
      |> Test.Fixtures.add_demographic_attrs(%{ethnicity: nil, occupation: nil, notes: nil})
      |> Cases.create_person!()

    [person: person]
  end

  describe "render" do
    test "initially shows current demographics values", %{conn: conn, person: person, user: user} do
      demographics = %{
        id: Euclid.Extra.List.only!(person.demographics).id,
        ethnicity: %{major: "hispanic_latinx_or_spanish_origin", detailed: ["cuban", "puerto_rican"]},
        gender_identity: ["female", "transgender_woman"]
      }

      {:ok, person_with_demographics} =
        person
        |> Cases.update_person({%{demographics: [demographics]}, Test.Fixtures.audit_meta(user)})

      Pages.DemographicsEdit.visit(conn, person_with_demographics)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_gender_identity_selections(%{
        "Declined to answer" => false,
        "Female" => true,
        "Transgender woman/trans woman/male-to-female (MTF)" => true,
        "Male" => false,
        "Transgender man/trans man/female-to-male (FTM)" => false,
        "Genderqueer/gender nonconforming neither exclusively male nor female" => false,
        "Additional gender category (or other), please specify" => false,
        "Unknown" => false
      })
      |> Pages.DemographicsEdit.assert_major_ethnicity_selection(%{
        "Unknown" => false,
        "Declined to answer" => false,
        "Not Hispanic, Latino/a, or Spanish origin" => false,
        "Hispanic, Latino/a, or Spanish origin" => true
      })
      |> Pages.DemographicsEdit.assert_detailed_ethnicity_selections(%{
        "Mexican, Mexican American, Chicano/a" => false,
        "Puerto Rican" => true,
        "Cuban" => true,
        "Another Hispanic, Latino/a or Spanish origin, please specify" => false
      })
    end
  end

  describe "gender identity" do
    test "selecting multiple gender identities", %{conn: conn, person: person, user: user} do
      demographics = %{id: Euclid.Extra.List.only!(person.demographics).id, gender_identity: ["female", "Original other"]}
      {:ok, person} = person |> Cases.update_person({%{demographics: [demographics]}, Test.Fixtures.audit_meta(user)})

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_gender_identity_selections(%{
        "Unknown" => false,
        "Declined to answer" => false,
        "Female" => true,
        "Transgender woman/trans woman/male-to-female (MTF)" => false,
        "Male" => false,
        "Transgender man/trans man/female-to-male (FTM)" => false,
        "Genderqueer/gender nonconforming neither exclusively male nor female" => false,
        "Additional gender category (or other), please specify" => true
      })
      |> Pages.DemographicsEdit.assert_gender_identity_other("Original other")
      |> Pages.submit_and_follow_redirect(
        conn,
        "#demographics-form",
        demographic_form: %{
          "gender_identity" => ["female", "transgender_woman"],
          "gender_identity_other" => "New other"
        }
      )
      |> Pages.Profile.assert_here(person)

      demographics(person.id).gender_identity |> assert_eq(["female", "transgender_woman", "New other"], ignore_order: true)
    end
  end

  describe "employment" do
    test "selecting employment status", %{conn: conn, person: person, user: user} do
      {:ok, person_with_no_jobs} = person |> Cases.update_person({%{marital_status: nil}, Test.Fixtures.audit_meta(user)})

      Pages.DemographicsEdit.visit(conn, person_with_no_jobs)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_employment_selections(%{
        "Not employed" => false,
        "Part time" => false,
        "Full time" => false,
        "Unknown" => false
      })
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"employment" => ["full_time"]})
      |> Pages.Profile.assert_employment("Full time")

      assert demographics(person_with_no_jobs.id).employment == "full_time"
    end
  end

  describe "ethnicity" do
    test "updating ethnicity", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form",
        demographic_form: %{
          "ethnicity" => ["declined_to_answer"],
          "ethnicity_hispanic_latinx_or_spanish_origin" => []
        }
      )
      |> Pages.Profile.assert_ethnicities(["Declined to answer"])

      assert demographics(person.id).ethnicity.major == "declined_to_answer"
    end

    test "choosing a detailed ethnicity(ies)", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form",
        demographic_form: %{
          "ethnicity" => ["hispanic_latinx_or_spanish_origin"],
          "ethnicity_hispanic_latinx_or_spanish_origin" => ["cuban", "puerto_rican"]
        }
      )
      |> Pages.Profile.assert_ethnicities(["Hispanic, Latino/a, or Spanish origin", "Cuban", "Puerto Rican"])

      updated_person = demographics(person.id)
      assert updated_person.ethnicity.major == "hispanic_latinx_or_spanish_origin"
      assert updated_person.ethnicity.detailed == ["cuban", "puerto_rican"]
    end
  end

  describe "marital status" do
    test "selecting status", %{conn: conn, person: person, user: user} do
      {:ok, person_without_marital_status} = person |> Cases.update_person({%{marital_status: nil}, Test.Fixtures.audit_meta(user)})

      Pages.DemographicsEdit.visit(conn, person_without_marital_status)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_marital_status_selection(%{"Single" => false, "Married" => false, "Unknown" => false})
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"marital_status" => ["single"]})
      |> Pages.Profile.assert_marital_status("Single")

      assert demographics(person_without_marital_status.id).marital_status == "single"
    end
  end

  describe "occupation" do
    test "it shows the existing occupation and can be edited", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_occupation("")
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"occupation" => "architect"})
      |> Pages.Profile.assert_occupation("architect")

      assert demographics(person.id).occupation == "architect"

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_occupation("architect")
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"occupation" => "deep-sea diver"})
      |> Pages.Profile.assert_occupation("deep-sea diver")

      assert demographics(person.id).occupation == "deep-sea diver"
    end
  end

  describe "notes" do
    test "it shows the existing notes and can be edited", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_notes("")
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"notes" => "foo bar baz"})
      |> Pages.Profile.assert_notes("foo bar baz")

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_notes("foo bar baz")
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"notes" => "the sea"})
      |> Pages.Profile.assert_notes("the sea")

      assert demographics(person.id).notes == "the sea"
    end
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.assert_confirmation_prompt("")
    end

    # temporarily skipped until form change event issue is resolved
    @tag :skip
    test "when the user changes the notes", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.change_form(%{"notes" => "New notes"})
      |> Pages.assert_confirmation_prompt("Your updates have not been saved. Discard updates?")
    end
  end

  describe "differentiating between demographics created by imports vs forms" do
    test "creates a new demographic with source 'form' if the only demographic is from an import", %{conn: conn, person: person} do
      demographics = person.demographics |> Enum.map(fn demo -> %{id: demo.id, source: "import"} end)
      {:ok, person} = Cases.update_person(person, {%{demographics: demographics}, Test.Fixtures.admin_audit_meta()})

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_occupation("")
      |> Pages.DemographicsEdit.change_form(%{"occupation" => "architect"})
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"occupation" => "architect"})

      assert [%{source: "import"}, %{source: "form", first_name: nil, occupation: "architect"}] = all_demographics(person.id)
    end

    test "updates a demographic if its source is 'form'", %{conn: conn, person: person} do
      demographics = person.demographics |> Enum.map(fn demo -> %{id: demo.id, source: "form"} end)
      {:ok, person} = Cases.update_person(person, {%{demographics: demographics}, Test.Fixtures.admin_audit_meta()})

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_occupation("")
      |> Pages.DemographicsEdit.change_form(%{"occupation" => "architect"})
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"occupation" => "architect"})

      assert [%{source: "form", occupation: "architect"}] = all_demographics(person.id)
    end
  end

  defp all_demographics(person_id) do
    Cases.get_person(person_id)
    |> Cases.preload_demographics()
    |> Map.get(:demographics)
  end

  defp demographics(person_id) do
    Cases.get_person(person_id)
    |> Cases.preload_demographics()
    |> Cases.Person.coalesce_demographics()
  end
end
