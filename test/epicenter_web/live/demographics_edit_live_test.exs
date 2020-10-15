defmodule EpicenterWeb.DemographicsEditLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user

  setup %{user: user} do
    person =
      Test.Fixtures.person_attrs(user, "alice")
      |> Test.Fixtures.add_demographic_attrs()
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
      |> Pages.DemographicsEdit.assert_ethnicity_selections(%{
        "Unknown" => false,
        "Declined to answer" => false,
        "Not Hispanic, Latino/a, or Spanish origin" => true,
        "Hispanic, Latino/a, or Spanish origin" => false
      })
    end
  end

  describe "ethnicity" do
    test "updating ethnicity", %{conn: conn, person: person} do
      Pages.DemographicsEdit.visit(conn, person)
      |> Pages.DemographicsEdit.assert_here()
      |> Pages.submit_and_follow_redirect(conn, "#demographics-form", person: %{"ethnicity" => %{"major" => "hispanic_latinx_or_spanish_origin"}})
      |> Pages.Profile.assert_ethnicity("Hispanic, Latino/a, or Spanish origin")

      #      assert_revision_count(person, 2)
      assert Cases.get_person(person.id).ethnicity.major == "hispanic_latinx_or_spanish_origin"
    end
  end
end
