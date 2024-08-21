defmodule EpiViewpointWeb.Presenters.PeoplePresenterTest do
  use EpiViewpoint.DataCase, async: true

  import EpiViewpoint.Test.HtmlAssertions, only: [assert_html_eq: 2]

  alias EpiViewpoint.Test

  alias EpiViewpoint.Cases
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Presenters.PeoplePresenter
  alias EpiViewpoint.ContactInvestigations

  @admin Test.Fixtures.admin()

  describe "full_name" do
    defp wrap(demo_attrs) do
      {:ok, person} = Test.Fixtures.person_attrs(@admin, "test") |> Test.Fixtures.add_demographic_attrs(demo_attrs) |> Cases.create_person()
      person
    end

    test "renders first and last name",
      do: assert(PeoplePresenter.full_name(wrap(%{first_name: "First", last_name: "TestuserLast"})) == "First TestuserLast")

    test "when there's just a first name",
      do: assert(PeoplePresenter.full_name(wrap(%{first_name: "First", last_name: nil})) == "First")

    test "when there's just a last name",
      do: assert(PeoplePresenter.full_name(wrap(%{first_name: nil, last_name: "TestuserLast"})) == "TestuserLast")

    test "when first name is blank",
      do: assert(PeoplePresenter.full_name(wrap(%{first_name: "", last_name: "TestuserLast"})) == "TestuserLast")
  end

  describe "latest_contact_investigation_status" do
    test "when interview status is pending" do
      assert(PeoplePresenter.latest_contact_investigation_status(person_with_contact_investigation(), ~D[2020-10-25]) == "Pending interview")
    end

    test "when interview status is ongoing" do
      assert(
        PeoplePresenter.latest_contact_investigation_status(
          person_with_contact_investigation(%{interview_started_at: ~U[2020-10-31 23:03:07Z]}),
          ~D[2020-10-25]
        ) == "Ongoing interview"
      )
    end

    test "when interview status is discontinued" do
      assert(
        PeoplePresenter.latest_contact_investigation_status(
          person_with_contact_investigation(%{interview_discontinued_at: ~U[2020-10-31 23:03:07Z]}),
          ~D[2020-10-25]
        ) == "Discontinued"
      )
    end

    test "when the interview is completed, and quarantine is pending monitoring" do
      assert(
        PeoplePresenter.latest_contact_investigation_status(
          person_with_contact_investigation(%{interview_completed_at: ~U[2020-10-31 23:03:07Z]}),
          ~D[2020-10-25]
        ) == "Pending monitoring"
      )
    end

    test "when the interview is completed, and quarantine is ongoing" do
      assert(
        PeoplePresenter.latest_contact_investigation_status(
          person_with_contact_investigation(%{
            interview_completed_at: ~U[2020-10-31 23:03:07Z],
            quarantine_monitoring_starts_on: ~D[2020-10-20],
            quarantine_monitoring_ends_on: ~D[2020-10-27]
          }),
          ~D[2020-10-25]
        ) == "Ongoing monitoring (2 days remaining)"
      )
    end

    test "when the interview is completed, and quarantine has concluded" do
      assert(
        PeoplePresenter.latest_contact_investigation_status(
          person_with_contact_investigation(%{interview_completed_at: ~U[2020-10-31 23:03:07Z], quarantine_concluded_at: ~U[2020-10-31 23:03:07Z]}),
          ~D[2020-10-25]
        ) == "Concluded monitoring"
      )
    end

    test "when there are more than one contact investigations, returns the most recently inserted one" do
      exposed_person = person_with_contact_investigation()

      {:ok, second_contact_investigation} =
        {Test.Fixtures.contact_investigation_attrs("second_contact_investigation", %{
           exposing_case_id: exposed_person.contact_investigations |> List.first() |> Map.get(:exposing_case_id),
           interview_started_at: ~U[2020-10-31 23:03:07Z]
         }), Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      second_contact_investigation
      |> Ecto.Changeset.change(exposed_person_id: exposed_person.id)
      |> Repo.update!()

      assert Cases.get_person(exposed_person.id, @admin)
             |> Cases.preload_contact_investigations(@admin)
             |> PeoplePresenter.latest_contact_investigation_status(~D[2020-10-25]) == "Ongoing interview"
    end
  end

  describe "search_result_details" do
    test "lists details" do
      alice =
        Test.Fixtures.person_attrs(@admin, "alice", %{})
        |> Test.Fixtures.add_demographic_attrs(%{first_name: "Alice", dob: ~D[1990-12-01], sex_at_birth: "female"})
        |> Cases.create_person!()

      Test.Fixtures.phone_attrs(@admin, alice, "phone1", number: "111-111-1222") |> Cases.create_phone!()
      Test.Fixtures.phone_attrs(@admin, alice, "phone2", number: "111-111-1333") |> Cases.create_phone!()
      Test.Fixtures.address_attrs(@admin, alice, "address1", 1000, type: "home") |> Cases.create_address!()
      Test.Fixtures.address_attrs(@admin, alice, "address2", 1001, type: "home") |> Cases.create_address!()

      PeoplePresenter.search_result_details(alice)
      |> Phoenix.HTML.safe_to_string()
      |> assert_html_eq("""
      <ul>
        <li>12/01/1990</li>
        <li>Female</li>
        <li>(111) 111-1222, (111) 111-1333</li>
        <li>1000 Test St, City, OH 00000; 1001 Test St, City, OH 00000</li>
      </ul>
      """)
    end

    test "doesn't render empty values" do
      alice = Test.Fixtures.person_attrs(@admin, "alice", %{}, demographics: false) |> Cases.create_person!()

      PeoplePresenter.search_result_details(alice)
      |> Phoenix.HTML.safe_to_string()
      |> assert_html_eq("""
      <ul>
      </ul>
      """)
    end
  end

  defp person_with_contact_investigation(contact_investigation_attrs \\ %{}) do
    alice = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()
    lab_result = Test.Fixtures.lab_result_attrs(alice, @admin, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()
    case_investigation = Test.Fixtures.case_investigation_attrs(alice, lab_result, @admin, "investigation") |> Cases.create_case_investigation!()

    contact_investigation_attrs = Map.merge(%{exposing_case_id: case_investigation.id}, contact_investigation_attrs)

    {:ok, contact_investigation} =
      {Test.Fixtures.contact_investigation_attrs("contact_investigation", contact_investigation_attrs), Test.Fixtures.admin_audit_meta()}
      |> ContactInvestigations.create()

    contact_investigation = ContactInvestigations.get(contact_investigation.id, @admin) |> ContactInvestigations.preload_exposed_person()
    contact_investigation.exposed_person |> Cases.preload_contact_investigations(@admin)
  end
end
