defmodule EpicenterWeb.AddVisitLiveTest do
  use EpicenterWeb.ConnCase, async: true

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  setup :register_and_log_in_user
  @admin Test.Fixtures.admin()

  describe "The add visit page" do
    setup %{user: user} do
      person = Test.Fixtures.person_attrs(user, "person") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(person, @admin, "lab-result", ~D[2020-10-27]) |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(person, lab_result, @admin, "case-investigation", %{symptom_onset_on: ~D[2021-02-18]})
        |> Cases.create_case_investigation!()

      place_1 = Test.Fixtures.place_attrs(@admin, "place-1", %{name: "the best place"}) |> Cases.create_place!()

      place_address =
        Test.Fixtures.place_address_attrs(@admin, place_1, "place-address-1", 1111)
        |> Cases.create_place_address!()

      [case_investigation: case_investigation, place_address: place_address]
    end

    test "showing a typeahead result", %{conn: conn, case_investigation: case_investigation, place_address: place_address} do
      Pages.AddVisit.visit(conn, case_investigation, place_address)
      |> Pages.AddVisit.assert_here(case_investigation, place_address)
      |> Pages.AddVisit.assert_place_name_and_address("the best place", "1111 Test St, City, OH 00000")
    end

    test "submits form correctly", %{conn: conn, case_investigation: case_investigation, place_address: place_address} do
      Pages.AddVisit.visit(conn, case_investigation, place_address)
      |> Pages.submit_and_follow_redirect(conn, "#add-visit-form",
        add_visit_form: %{
          "relationship" => "A reasonable bit of text",
          "occurred_on" => "09/06/2020"
        }
      )
    end
  end
end
