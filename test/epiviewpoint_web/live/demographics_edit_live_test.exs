defmodule EpiViewpointWeb.DemographicsEditLiveTest do
  use EpiViewpointWeb.ConnCase, async: true

  alias EpiViewpoint.Accounts.User
  alias EpiViewpoint.Cases
  alias EpiViewpoint.Cases.Person
  alias EpiViewpoint.Repo
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person =
      Test.Fixtures.person_attrs(user, "alice")
      |> Test.Fixtures.add_demographic_attrs(%{
        employment: nil,
        ethnicity: nil,
        gender_identity: nil,
        marital_status: nil,
        notes: nil,
        occupation: nil,
        race: nil,
        sex_at_birth: nil
      })
      |> Cases.create_person!()

    [person: person]
  end

  defp update_demographics(%User{} = author, %Person{} = person, attrs) do
    demographics = Map.merge(%{id: Euclid.Extra.List.only!(person.demographics).id}, Enum.into(attrs, %{}))
    person |> Cases.update_person({%{demographics: [demographics]}, Test.Fixtures.audit_meta(author)})
  end

  describe "render" do
    test "records an audit log entry", %{conn: conn, person: person, user: user} do
      AuditLogAssertions.expect_phi_view_logs(2)
      Pages.DemographicsEdit.visit(conn, person)
      AuditLogAssertions.verify_phi_view_logged(user, person)
    end

    test "initially shows current demographics values", %{conn: conn, person: person, user: user} do
      {:ok, person_with_demographics} =
        update_demographics(
          user,
          person,
          id: Euclid.Extra.List.only!(person.demographics).id,
          employment_status: "not-employed",
          ethnicity: %{major: "hispanic_latinx_or_spanish_origin", detailed: ["cuban", "puerto_rican"]},
          gender_identity: ["female", "transgender_woman"],
          marital_status: "single",
          race: %{"major" => ["asian"]},
          sex_at_birth: "female"
        )

      Pages.DemographicsEdit.visit(conn, person_with_demographics)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_major_ethnicity_selections(%{
        "Unknown" => false,
        "Declined to answer" => false,
        "Not Hispanic, Latino/a, or Spanish origin" => false,
        "Hispanic, Latino/a, or Spanish origin" => true
      })
      |> Pages.DemographicsEdit.assert_detailed_ethnicity_selections(%{
        "Mexican, Mexican American, Chicano/a" => false,
        "Puerto Rican" => true,
        "Cuban" => true,
        "Another Hispanic, Latino/a or Spanish origin" => false
      })
      |> Pages.DemographicsEdit.assert_gender_identity_selections(%{
        "Declined to answer" => false,
        "Female" => true,
        "Transgender woman/trans woman/male-to-female (MTF)" => true,
        "Male" => false,
        "Transgender man/trans man/female-to-male (FTM)" => false,
        "Genderqueer/gender nonconforming neither exclusively male nor female" => false,
        "Additional gender category (or other)" => false,
        "Unknown" => false
      })
      |> Pages.DemographicsEdit.assert_marital_status_selection(%{
        "Married" => false,
        "Single" => true,
        "Unknown" => false
      })
      |> Pages.DemographicsEdit.assert_race_selection(%{
        "American Indian or Alaska Native" => false,
        "Asian" => true,
        "Black or African American" => false,
        "Declined to answer" => false,
        "Native Hawaiian or Other Pacific Islander" => false,
        "Other" => false,
        "Unknown" => false,
        "White" => false
      })
      |> Pages.DemographicsEdit.assert_sex_at_birth_selection(%{
        "Declined to answer" => false,
        "Female" => true,
        "Intersex" => false,
        "Male" => false,
        "Unknown" => false
      })
    end
  end

  describe "gender identity" do
    test "selecting multiple gender identities", %{conn: conn, person: person, user: user} do
      {:ok, person} = update_demographics(user, person, gender_identity: ["female", "Original other"])

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_gender_identity_selections(%{
        "Unknown" => false,
        "Declined to answer" => false,
        "Female" => true,
        "Transgender woman/trans woman/male-to-female (MTF)" => false,
        "Male" => false,
        "Transgender man/trans man/female-to-male (FTM)" => false,
        "Genderqueer/gender nonconforming neither exclusively male nor female" => false,
        "Additional gender category (or other)" => true
      })
      |> Pages.DemographicsEdit.assert_gender_identity_other("Original other")
      |> Pages.submit_and_follow_redirect(
        conn,
        "#demographics-form",
        demographic_form: %{
          "gender_identity" => %{"major" => %{"values" => ["female", "transgender_woman"], "other" => "New other"}}
        }
      )
      |> Pages.Profile.assert_here(person)

      demographics(person.id).gender_identity |> assert_eq(["female", "transgender_woman", "New other"], ignore_order: true)
    end
  end

  describe "employment" do
    test "selecting employment status", %{conn: conn, person: person, user: user} do
      {:ok, person} = update_demographics(user, person, employment: "not_employed")

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_employment_selections(%{
        "Not employed" => true,
        "Part time" => false,
        "Full time" => false,
        "Unknown" => false
      })
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"employment" => "full_time"})
      |> Pages.Profile.assert_employment("Full time")

      assert demographics(person.id).employment == "full_time"
    end
  end

  describe "ethnicity" do
    test "updating ethnicity", %{conn: conn, person: person, user: user} do
      assert demographics(person.id).ethnicity == nil
      {:ok, person} = update_demographics(user, person, ethnicity: %{major: "not_hispanic_latinx_or_spanish_origin"})

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_major_ethnicity_selections(%{
        "Declined to answer" => false,
        "Hispanic, Latino/a, or Spanish origin" => false,
        "Not Hispanic, Latino/a, or Spanish origin" => true,
        "Unknown" => false
      })
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form",
        demographic_form: %{
          "ethnicity" => %{
            "major" => %{"values" => ["declined_to_answer"]},
            "detailed" => %{}
          }
        }
      )
      |> Pages.Profile.assert_ethnicities(["Declined to answer"])

      assert demographics(person.id).ethnicity.major == "declined_to_answer"
      assert demographics(person.id).ethnicity.detailed == nil
    end

    test "choosing detailed ethnicities", %{conn: conn, person: person, user: user} do
      {:ok, person} = update_demographics(user, person, ethnicity: %{major: "hispanic_latinx_or_spanish_origin", detailed: ["puerto_rican"]})

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_detailed_ethnicity_selections(%{
        "Another Hispanic, Latino/a or Spanish origin" => false,
        "Cuban" => false,
        "Mexican, Mexican American, Chicano/a" => false,
        "Puerto Rican" => true
      })
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form",
        demographic_form: %{
          "ethnicity" => %{
            "major" => %{"values" => ["hispanic_latinx_or_spanish_origin"]},
            "detailed" => %{"hispanic_latinx_or_spanish_origin" => %{"values" => ["cuban", "puerto_rican"], "other" => "Other ethnicity"}}
          }
        }
      )
      |> Pages.Profile.assert_ethnicities(["Hispanic, Latino/a, or Spanish origin", "Cuban", "Puerto Rican", "Other ethnicity"])

      updated_person = demographics(person.id)
      assert updated_person.ethnicity.major == "hispanic_latinx_or_spanish_origin"
      assert updated_person.ethnicity.detailed == ["Other ethnicity", "cuban", "puerto_rican"]
    end
  end

  describe "marital status" do
    test "selecting status", %{conn: conn, person: person, user: user} do
      {:ok, person} = update_demographics(user, person, marital_status: "married")

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_marital_status_selection(%{"Single" => false, "Married" => true, "Unknown" => false})
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"marital_status" => "single"})
      |> Pages.Profile.assert_marital_status("Single")

      assert demographics(person.id).marital_status == "single"
    end
  end

  describe "notes" do
    test "shows the existing notes and can be edited", %{conn: conn, person: person, user: user} do
      {:ok, person} = update_demographics(user, person, notes: "old notes")

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_notes("old notes")
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"notes" => "new notes"})
      |> Pages.Profile.assert_notes("new notes")

      assert demographics(person.id).notes == "new notes"
    end
  end

  describe "occupation" do
    test "it shows the existing occupation and can be edited", %{conn: conn, person: person, user: user} do
      {:ok, person} = update_demographics(user, person, occupation: "old occupation")

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_occupation("old occupation")
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"occupation" => "new occupation"})
      |> Pages.Profile.assert_occupation("new occupation")

      assert demographics(person.id).occupation == "new occupation"
    end
  end

  describe "race" do
    test "it shows the existing race and can be edited", %{conn: conn, person: person, user: user} do
      {:ok, person} = update_demographics(user, person, race: %{"major" => ["declined_to_answer"]})

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_race_selection(%{
        "Declined to answer" => true,
        "Unknown" => false,
        "American Indian or Alaska Native" => false,
        "Asian" => false,
        "Black or African American" => false,
        "Native Hawaiian or Other Pacific Islander" => false,
        "Other" => false,
        "White" => false
      })
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"race" => %{"major" => %{"values" => ["asian"]}}})
      |> Pages.Profile.assert_race(["Asian"])

      assert demographics(person.id).race == %{"detailed" => %{}, "major" => ["asian"]}
    end
  end

  describe "sex at birth" do
    test "it shows the existing sex at birth and can be edited", %{conn: conn, person: person, user: user} do
      {:ok, person} = update_demographics(user, person, sex_at_birth: "female")

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_sex_at_birth_selection(%{
        "Unknown" => false,
        "Declined to answer" => false,
        "Female" => true,
        "Intersex" => false,
        "Male" => false
      })
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic_form: %{"sex_at_birth" => "male"})
      |> Pages.Profile.assert_sex_at_birth("Male")

      assert demographics(person.id).sex_at_birth == "male"
    end
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.refute_confirmation_prompt_active()
    end

    test "when the user changes the notes", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.change_form(%{"notes" => "New notes"})
      |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")
    end

    test "when the user changes a demographic value", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.change_form(%{"employment" => "full_time"})
      |> Pages.assert_confirmation_prompt_active("Your updates have not been saved. Discard updates?")
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
    Repo.get(Person, person_id)
    |> Cases.preload_demographics()
    |> Map.get(:demographics)
  end

  defp demographics(person_id) do
    Repo.get(Person, person_id)
    |> Cases.preload_demographics()
    |> Cases.Person.coalesce_demographics()
  end
end
