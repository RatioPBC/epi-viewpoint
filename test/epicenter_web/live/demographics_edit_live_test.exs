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
      |> Test.Fixtures.add_demographic_attrs(ethnicity: %{major: "hispanic_latinx_or_spanish_origin", detailed: ["cuban", "puerto_rican"]})
      |> Cases.create_person!()

    [person: person]
  end

  describe "render" do
    test "initially shows current demographics values", %{conn: conn, person: person} do
      # TODO don't hardcode all the checkboxes to true
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.DemographicsEdit.assert_gender_identity_selections(%{
        "Declined to answer" => true,
        "Female" => true,
        "Transgender woman/trans woman/male-to-female (MTF)" => true,
        "Male" => true,
        "Transgender man/trans man/female-to-male (FTM)" => true,
        "Genderqueer/gender nonconforming neither exclusively male nor female" => true,
        "Additional gender category (or other)" => true
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

  describe "ethnicity" do
    test "updating ethnicity", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", person: %{"ethnicity" => %{"major" => "declined_to_answer"}})
      |> Pages.Profile.assert_major_ethnicity("Declined to answer")

      # TODO: - should we assert on the audit log?      assert_revision_count(person, 2)
      assert Cases.get_person(person.id).ethnicity.major == "declined_to_answer"
    end

    test "choosing a detailed ethnicity(ies)", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form",
        person: %{"ethnicity" => %{"major" => "hispanic_latinx_or_spanish_origin", "detailed" => ["cuban", "puerto_rican"]}}
      )
      |> Pages.Profile.assert_major_ethnicity("Hispanic, Latino/a, or Spanish origin")
      |> Pages.Profile.assert_detailed_ethnicities(["Cuban", "Puerto Rican"])

      updated_person = Cases.get_person(person.id)
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
        "Hispanic, Latino/a, or Spanish origin" => true
      })
      |> Pages.DemographicsEdit.assert_detailed_ethnicity_selections(%{
        "Mexican, Mexican American, Chicano/a" => false,
        "Puerto Rican" => true,
        "Cuban" => true,
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
  end

  describe "detailed_ethnicity_option_checked" do
    test "it returns true when the given detailed ethnicity option is set for the given person" do
      assert DemographicsEditLive.detailed_ethnicity_checked(%{detailed: ["detailed_a", "detailed_b"]}, "detailed_b")
      refute DemographicsEditLive.detailed_ethnicity_checked(%{detailed: ["detailed_a", "detailed_b"]}, "detailed_c")
      refute DemographicsEditLive.detailed_ethnicity_checked(%{detailed: nil}, "detailed_c")
    end
  end
end
