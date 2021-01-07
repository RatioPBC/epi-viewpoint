defmodule EpicenterWeb.Presenters.PeoplePresenterTest do
  use Epicenter.DataCase, async: true

  alias Epicenter.Test

  alias Epicenter.Cases
  alias Epicenter.Test
  alias EpicenterWeb.Presenters.PeoplePresenter
  alias Epicenter.ContactInvestigations

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

  describe("latest_contact_investigation_status") do
    defp person_with_contact_investigation(contact_investigation_attrs \\ %{}) do
      #      {:ok, person} = Test.Fixtures.person_attrs(@admin, "test") |> Test.Fixtures.add_demographic_attrs(demo_attrs) |> Cases.create_person()
      #      person

      alice = Test.Fixtures.person_attrs(@admin, "alice") |> Cases.create_person!()
      lab_result = Test.Fixtures.lab_result_attrs(alice, @admin, "lab_result", ~D[2020-10-27]) |> Cases.create_lab_result!()
      case_investigation = Test.Fixtures.case_investigation_attrs(alice, lab_result, @admin, "investigation") |> Cases.create_case_investigation!()

      contact_investigation_attrs = Map.merge(%{exposing_case_id: case_investigation.id}, contact_investigation_attrs)

      {:ok, contact_investigation} =
        {Test.Fixtures.contact_investigation_attrs("contact_investigation", contact_investigation_attrs), Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      contact_investigation = ContactInvestigations.get(contact_investigation.id) |> ContactInvestigations.preload_exposed_person()
      contact_investigation.exposed_person |> Cases.preload_contact_investigations()
    end

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
  end
end
