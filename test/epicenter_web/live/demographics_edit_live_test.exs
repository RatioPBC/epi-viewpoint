defmodule EpicenterWeb.DemographicsEditLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.DemographicsEditLive
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
      {:ok, person_with_ethnicities} =
        person
        |> Cases.update_person({
          %{
            demographics: [
              %{
                id: Euclid.Extra.List.only!(person.demographics).id,
                ethnicity: %{major: "hispanic_latinx_or_spanish_origin", detailed: ["cuban", "puerto_rican"]},
                gender_identity: ["Female", "Transgender woman/trans woman/male-to-female (MTF)"]
              }
            ]
          },
          Test.Fixtures.audit_meta(user)
        })

      # TODO don't hardcode all the checkboxes to true
      Pages.DemographicsEdit.visit(conn, person_with_ethnicities)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_gender_identity_selections(%{
        "Declined to answer" => false,
        "Female" => true,
        "Transgender woman/trans woman/male-to-female (MTF)" => true,
        "Male" => false,
        "Transgender man/trans man/female-to-male (FTM)" => false,
        "Genderqueer/gender nonconforming neither exclusively male nor female" => false,
        "Additional gender category (or other)" => false
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
        "Another Hispanic, Latino/a or Spanish origin" => false
      })
    end
  end

  describe "gender identity" do
    test "unchecking the last gender identity", %{conn: conn, person: person, user: user} do
      {:ok, person} =
        person
        |> Cases.update_person(
          {%{demographics: [%{id: Euclid.Extra.List.only!(person.demographics).id, gender_identity: ["Female"]}]}, Test.Fixtures.audit_meta(user)}
        )

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_gender_identity_selections(%{
        "Declined to answer" => false,
        "Female" => true,
        "Transgender woman/trans woman/male-to-female (MTF)" => false,
        "Male" => false,
        "Transgender man/trans man/female-to-male (FTM)" => false,
        "Genderqueer/gender nonconforming neither exclusively male nor female" => false,
        "Additional gender category (or other)" => false
      })
      # The line below is unrealistic. the "gender_identity" field needs to be missing from
      # the person_params passes to handle_event("form-change"...), but when we don't include
      # it LiveViewTest *helpfully* adds back the gender_identity that is currently selected,
      # so we can't reproduce (in a test) the bug where the last checkbox refuses to uncheck.
      |> Pages.DemographicsEdit.change_form(%{"gender_identity" => []})
      |> Pages.DemographicsEdit.assert_gender_identity_selections(%{
        "Declined to answer" => false,
        "Female" => false,
        "Transgender woman/trans woman/male-to-female (MTF)" => false,
        "Male" => false,
        "Transgender man/trans man/female-to-male (FTM)" => false,
        "Genderqueer/gender nonconforming neither exclusively male nor female" => false,
        "Additional gender category (or other)" => false
      })
    end
  end

  describe "employment" do
    test "selecting employment status", %{conn: conn, person: person, user: user} do
      {:ok, person_with_no_jobs} = person |> Cases.update_person({%{marital_status: nil}, Test.Fixtures.audit_meta(user)})

      Pages.DemographicsEdit.visit(conn, person_with_no_jobs)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_employment_selections(%{"Not employed" => false, "Part time" => false, "Full time" => false})
      |> Pages.DemographicsEdit.change_form(%{"employment" => "full_time"})
      |> Pages.DemographicsEdit.assert_employment_selections(%{"Not employed" => false, "Part time" => false, "Full time" => true})
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic: %{"employment" => "full_time"})
      |> Pages.Profile.assert_employment("Full time")

      assert demographics(person_with_no_jobs.id).employment == "full_time"
    end
  end

  describe "ethnicity" do
    test "updating ethnicity", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic: %{"ethnicity" => %{"major" => "declined_to_answer"}})
      |> Pages.Profile.assert_major_ethnicity("Declined to answer")

      # TODO: - should we assert on the audit log?      assert_revision_count(person, 2)
      assert demographics(person.id).ethnicity.major == "declined_to_answer"
    end

    test "choosing a detailed ethnicity(ies)", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form",
        demographic: %{"ethnicity" => %{"major" => "hispanic_latinx_or_spanish_origin", "detailed" => ["cuban", "puerto_rican"]}}
      )
      |> Pages.Profile.assert_major_ethnicity("Hispanic, Latino/a, or Spanish origin")
      |> Pages.Profile.assert_detailed_ethnicities(["Cuban", "Puerto Rican"])

      updated_person = demographics(person.id)
      assert updated_person.ethnicity.major == "hispanic_latinx_or_spanish_origin"
      assert updated_person.ethnicity.detailed == ["cuban", "puerto_rican"]
    end

    test "toggling major ethnicity radio deselects detailed ethnicity checkboxes", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_major_ethnicity_selection(%{
        "Unknown" => false,
        "Declined to answer" => false,
        "Not Hispanic, Latino/a, or Spanish origin" => false,
        "Hispanic, Latino/a, or Spanish origin" => false
      })
      |> Pages.DemographicsEdit.assert_detailed_ethnicity_selections(%{
        "Mexican, Mexican American, Chicano/a" => false,
        "Puerto Rican" => false,
        "Cuban" => false,
        "Another Hispanic, Latino/a or Spanish origin" => false
      })
      |> Pages.DemographicsEdit.change_form(%{"ethnicity" => %{"major" => "not_hispanic_latinx_or_spanish_origin"}})
      |> Pages.DemographicsEdit.assert_major_ethnicity_selected("Not Hispanic, Latino/a, or Spanish origin")
      |> Pages.DemographicsEdit.assert_detailed_ethnicities_selected([])
      |> Pages.DemographicsEdit.change_form(%{
        "ethnicity" => %{"major" => "hispanic_latinx_or_spanish_origin", "detailed" => ["cuban", "puerto_rican"]}
      })
      |> Pages.DemographicsEdit.assert_major_ethnicity_selected("Hispanic, Latino/a, or Spanish origin")
      |> Pages.DemographicsEdit.assert_detailed_ethnicities_selected(["Cuban", "Puerto Rican"])
      |> Pages.DemographicsEdit.change_form(%{"ethnicity" => %{"major" => "unknown", "detailed" => []}})
      |> Pages.DemographicsEdit.assert_major_ethnicity_selected("Unknown")
      |> Pages.DemographicsEdit.assert_detailed_ethnicities_selected([])
      |> Pages.DemographicsEdit.change_form(%{"ethnicity" => %{"major" => "unknown", "detailed" => ["cuban"]}})
      |> Pages.DemographicsEdit.assert_major_ethnicity_selected("Hispanic, Latino/a, or Spanish origin")
      |> Pages.DemographicsEdit.assert_detailed_ethnicities_selected(["Cuban"])
    end

    test "selecting major ethnicity non-hispanic(et al) first", %{conn: conn, person: person, user: user} do
      {:ok, person_without_ethnicity} = person |> Cases.update_person({%{ethnicity: nil}, Test.Fixtures.audit_meta(user)})

      Pages.DemographicsEdit.visit(conn, person_without_ethnicity)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_major_ethnicity_selection(%{
        "Unknown" => false,
        "Declined to answer" => false,
        "Not Hispanic, Latino/a, or Spanish origin" => false,
        "Hispanic, Latino/a, or Spanish origin" => false
      })
      |> Pages.DemographicsEdit.assert_detailed_ethnicity_selections(%{
        "Mexican, Mexican American, Chicano/a" => false,
        "Puerto Rican" => false,
        "Cuban" => false,
        "Another Hispanic, Latino/a or Spanish origin" => false
      })
      |> Pages.DemographicsEdit.change_form(%{"ethnicity" => %{"major" => "not_hispanic_latinx_or_spanish_origin"}})
      |> Pages.DemographicsEdit.assert_major_ethnicity_selected("Not Hispanic, Latino/a, or Spanish origin")
      |> Pages.DemographicsEdit.assert_detailed_ethnicities_selected([])
    end

    test "selecting major ethnicity hispanic(et al) first", %{conn: conn, person: person, user: user} do
      {:ok, person_without_ethnicity} = person |> Cases.update_person({%{ethnicity: nil}, Test.Fixtures.audit_meta(user)})

      Pages.DemographicsEdit.visit(conn, person_without_ethnicity)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_major_ethnicity_selection(%{
        "Unknown" => false,
        "Declined to answer" => false,
        "Not Hispanic, Latino/a, or Spanish origin" => false,
        "Hispanic, Latino/a, or Spanish origin" => false
      })
      |> Pages.DemographicsEdit.assert_detailed_ethnicity_selections(%{
        "Mexican, Mexican American, Chicano/a" => false,
        "Puerto Rican" => false,
        "Cuban" => false,
        "Another Hispanic, Latino/a or Spanish origin" => false
      })
      |> Pages.DemographicsEdit.change_form(%{"ethnicity" => %{"major" => "hispanic_latinx_or_spanish_origin"}})
      |> Pages.DemographicsEdit.assert_major_ethnicity_selected("Hispanic, Latino/a, or Spanish origin")
      |> Pages.DemographicsEdit.assert_detailed_ethnicities_selected([])
    end

    test "selecting detailed ethnicity hispanic(et al) first", %{conn: conn, person: person, user: user} do
      {:ok, person_without_ethnicity} =
        person
        |> Cases.update_person(
          {%{demographics: [%{id: Euclid.Extra.List.only!(person.demographics).id, ethnicity: %{major: "hispanic_latinx_or_spanish_origin"}}]},
           Test.Fixtures.audit_meta(user)}
        )

      Pages.DemographicsEdit.visit(conn, person_without_ethnicity)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_major_ethnicity_selection(%{
        "Unknown" => false,
        "Declined to answer" => false,
        "Not Hispanic, Latino/a, or Spanish origin" => false,
        "Hispanic, Latino/a, or Spanish origin" => true
      })
      |> Pages.DemographicsEdit.assert_detailed_ethnicity_selections(%{
        "Mexican, Mexican American, Chicano/a" => false,
        "Puerto Rican" => false,
        "Cuban" => false,
        "Another Hispanic, Latino/a or Spanish origin" => false
      })
      |> Pages.DemographicsEdit.change_form(%{"ethnicity" => %{"detailed" => ["cuban"]}})
      |> Pages.DemographicsEdit.assert_major_ethnicity_selected("Hispanic, Latino/a, or Spanish origin")
      |> Pages.DemographicsEdit.assert_detailed_ethnicities_selected(["Cuban"])
    end

    test "selecting detailed ethnicity first", %{conn: conn, person: person, user: user} do
      {:ok, person_without_ethnicity} = person |> Cases.update_person({%{ethnicity: nil}, Test.Fixtures.audit_meta(user)})

      Pages.DemographicsEdit.visit(conn, person_without_ethnicity)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_major_ethnicity_selection(%{
        "Unknown" => false,
        "Declined to answer" => false,
        "Not Hispanic, Latino/a, or Spanish origin" => false,
        "Hispanic, Latino/a, or Spanish origin" => false
      })
      |> Pages.DemographicsEdit.assert_detailed_ethnicity_selections(%{
        "Mexican, Mexican American, Chicano/a" => false,
        "Puerto Rican" => false,
        "Cuban" => false,
        "Another Hispanic, Latino/a or Spanish origin" => false
      })
      |> Pages.DemographicsEdit.change_form(%{"ethnicity" => %{"detailed" => ["cuban"]}})
      |> Pages.DemographicsEdit.assert_major_ethnicity_selected("Hispanic, Latino/a, or Spanish origin")
      |> Pages.DemographicsEdit.assert_detailed_ethnicities_selected(["Cuban"])
    end

    test "selecting major ethnicity non-hispanic after selecting a detailed ethnicity", %{conn: conn, person: person, user: user} do
      {:ok, person_without_ethnicity} = person |> Cases.update_person({%{ethnicity: nil}, Test.Fixtures.audit_meta(user)})

      Pages.DemographicsEdit.visit(conn, person_without_ethnicity)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_major_ethnicity_selection(%{
        "Unknown" => false,
        "Declined to answer" => false,
        "Not Hispanic, Latino/a, or Spanish origin" => false,
        "Hispanic, Latino/a, or Spanish origin" => false
      })
      |> Pages.DemographicsEdit.assert_detailed_ethnicity_selections(%{
        "Mexican, Mexican American, Chicano/a" => false,
        "Puerto Rican" => false,
        "Cuban" => false,
        "Another Hispanic, Latino/a or Spanish origin" => false
      })
      |> Pages.DemographicsEdit.change_form(%{"ethnicity" => %{"detailed" => ["cuban"]}})
      |> Pages.DemographicsEdit.assert_major_ethnicity_selected("Hispanic, Latino/a, or Spanish origin")
      |> Pages.DemographicsEdit.assert_detailed_ethnicities_selected(["Cuban"])
      |> Pages.DemographicsEdit.change_form(%{"ethnicity" => %{"major" => "unknown", "detailed" => ["cuban"]}})
      |> Pages.DemographicsEdit.assert_major_ethnicity_selected("Unknown")
      |> Pages.DemographicsEdit.assert_detailed_ethnicities_selected([])
    end

    test "selecting ethnicities does not reset state of form", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.change_form(%{"occupation" => "architect", "notes" => "the building is great!"})
      |> Pages.DemographicsEdit.assert_occupation("architect")
      |> Pages.DemographicsEdit.assert_notes("the building is great!")
      |> Pages.DemographicsEdit.change_form(%{"ethnicity" => %{"major" => "hispanic_latinx_or_spanish_origin"}})
      |> Pages.DemographicsEdit.assert_occupation("architect")
      |> Pages.DemographicsEdit.assert_notes("the building is great!")
    end
  end

  describe "marital status" do
    test "selecting status", %{conn: conn, person: person, user: user} do
      {:ok, person_without_marital_status} = person |> Cases.update_person({%{marital_status: nil}, Test.Fixtures.audit_meta(user)})

      Pages.DemographicsEdit.visit(conn, person_without_marital_status)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_marital_status_selection(%{"Single" => false, "Married" => false})
      |> Pages.DemographicsEdit.change_form(%{"marital_status" => "single"})
      |> Pages.DemographicsEdit.assert_marital_status_selection(%{"Single" => true, "Married" => false})
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic: %{"marital_status" => "single"})
      |> Pages.Profile.assert_marital_status("Single")

      assert demographics(person_without_marital_status.id).marital_status == "single"
    end
  end

  describe "occupation" do
    test "it shows the existing occupation and can be edited", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_occupation("")
      |> Pages.DemographicsEdit.change_form(%{"occupation" => "architect"})
      |> Pages.DemographicsEdit.assert_occupation("architect")
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic: %{"occupation" => "architect"})
      |> Pages.Profile.assert_occupation("architect")

      assert demographics(person.id).occupation == "architect"

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_occupation("architect")
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic: %{"occupation" => "deep-sea diver"})
      |> Pages.Profile.assert_occupation("deep-sea diver")

      assert demographics(person.id).occupation == "deep-sea diver"
    end
  end

  describe "notes" do
    test "it shows the existing notes and can be edited", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_notes("")
      |> Pages.DemographicsEdit.change_form(%{"notes" => "foo bar baz"})
      |> Pages.DemographicsEdit.assert_notes("foo bar baz")
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic: %{"notes" => "foo bar baz"})
      |> Pages.Profile.assert_notes("foo bar baz")

      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_notes("foo bar baz")
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic: %{"notes" => "the sea"})
      |> Pages.Profile.assert_notes("the sea")

      assert demographics(person.id).notes == "the sea"
    end
  end

  describe "warning the user when navigation will erase their changes" do
    test "before the user changes anything", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.assert_confirmation_prompt("")
    end

    test "when the user changes the notes", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.change_form(%{"notes" => "New notes"})
      |> Pages.assert_confirmation_prompt("Your updates have not been saved. Discard updates?")
    end
  end

  describe "detailed_ethnicity_option_checked" do
    test "it returns true when the given detailed ethnicity option is set for the given person" do
      assert DemographicsEditLive.detailed_ethnicity_checked(%{detailed: ["detailed_a", "detailed_b"]}, "detailed_b")
      refute DemographicsEditLive.detailed_ethnicity_checked(%{detailed: ["detailed_a", "detailed_b"]}, "detailed_c")
      refute DemographicsEditLive.detailed_ethnicity_checked(%{detailed: nil}, "detailed_c")
    end
  end

  test "making a 'form' demographic", %{conn: conn, person: person} do
    {:ok, person} =
      Cases.update_person(
        person,
        {%{demographics: person.demographics |> Enum.map(fn demo -> %{id: demo.id, source: "import"} end)}, Test.Fixtures.admin_audit_meta()}
      )

    Pages.DemographicsEdit.visit(conn, person)
    |> Pages.DemographicsEdit.assert_occupation("")
    |> Pages.DemographicsEdit.change_form(%{"occupation" => "architect"})
    |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic: %{"occupation" => "architect"})

    assert [%{source: "import"}, %{source: "form", first_name: nil, occupation: "architect"}] = all_demographics(person.id)
  end

  test "modifying the 'form' demographic", %{conn: conn, person: person} do
    {:ok, person} =
      Cases.update_person(
        person,
        {%{demographics: person.demographics |> Enum.map(fn demo -> %{id: demo.id, source: "form"} end)}, Test.Fixtures.admin_audit_meta()}
      )

    Pages.DemographicsEdit.visit(conn, person)
    |> Pages.DemographicsEdit.assert_occupation("")
    |> Pages.DemographicsEdit.change_form(%{"occupation" => "architect"})
    |> Pages.submit_and_follow_redirect(conn, "#demographics-form", demographic: %{"occupation" => "architect"})

    assert [%{source: "form", occupation: "architect"}] = all_demographics(person.id)
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
