defmodule EpicenterWeb.ContactInvestigationTest do
  use EpicenterWeb.ConnCase, async: true

  import EpicenterWeb.LiveComponent.Helpers
  import Phoenix.LiveViewTest

  alias Epicenter.Accounts
  alias Epicenter.Cases
  alias Epicenter.ContactInvestigations
  alias Epicenter.Test
  alias EpicenterWeb.Test.Components
  alias EpicenterWeb.Test.Pages

  defmodule TestLiveView do
    alias EpicenterWeb.ContactInvestigation

    @admin Test.Fixtures.admin()

    def default_contact_investigation() do
      sick_person =
        Test.Fixtures.person_attrs(@admin, "alice")
        |> Cases.create_person!()

      lab_result =
        Test.Fixtures.lab_result_attrs(sick_person, @admin, "lab_result", ~D[2020-08-07])
        |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(
          sick_person,
          lab_result,
          @admin,
          "the contagious person's case investigation"
        )
        |> Cases.create_case_investigation!()

      {:ok, contact_investigation} =
        {Test.Fixtures.contact_investigation_attrs("contact_investigation", %{
           clinical_status: "asymptomatic",
           exposed_on: ~D[2020-12-14],
           exposing_case_id: case_investigation.id,
           interview_started_at: ~U[2020-01-01 22:03:07Z],
           most_recent_date_together: ~D[2020-12-15],
           symptoms: ["cough", "headache"]
         }), Test.Fixtures.admin_audit_meta()}
        |> ContactInvestigations.create()

      contact_investigation
      |> ContactInvestigations.preload_exposing_case()
      |> Cases.preload_investigation_notes()
    end

    use EpicenterWeb.Test.ComponentEmbeddingLiveView,
      default_assigns: [
        current_user: %Accounts.User{},
        current_user_id: "test-user-id",
        contact_investigation: default_contact_investigation(),
        on_add_note: &Function.identity/1,
        on_delete_note: &Function.identity/1
      ]

    def render(assigns) do
      ~H"""
      <%= l_component(
        ContactInvestigation,
        "renders-a-contact-investigation",
        contact_investigation: @contact_investigation,
        current_user_id: @current_user_id,
        on_add_note: @on_add_note,
        on_delete_note: @on_delete_note
      ) %>
      """
    end
  end

  describe "initial render" do
    test "renders the clinical details correctly", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, TestLiveView)

      Components.ContactInvestigation.assert_clinical_details(view, %{
        clinical_status: "Asymptomatic",
        exposed_on: "12/14/2020",
        symptoms: "Cough, Headache"
      })
    end
  end

  describe "rendering the component inside the profile" do
    @admin Test.Fixtures.admin()

    setup :register_and_log_in_user

    setup do
      sick_person =
        Test.Fixtures.person_attrs(@admin, "alice")
        |> Cases.create_person!()

      lab_result =
        Test.Fixtures.lab_result_attrs(sick_person, @admin, "lab_result", ~D[2020-08-07])
        |> Cases.create_lab_result!()

      case_investigation =
        Test.Fixtures.case_investigation_attrs(
          sick_person,
          lab_result,
          @admin,
          "the contagious person's case investigation"
        )
        |> Cases.create_case_investigation!()

      [case_investigation: case_investigation]
    end

    test "started case investigations that lack a clinical details show the values as 'None'", %{
      conn: conn,
      case_investigation: case_investigation
    } do
      {:ok, contact_investigation} =
        Test.Fixtures.contact_investigation_attrs(
          "contact_investigation",
          %{
            interview_started_at: NaiveDateTime.utc_now(),
            clinical_status: nil,
            symptom_onset_on: nil,
            exposing_case_id: case_investigation.id
          }
        )
        |> Test.Fixtures.wrap_with_audit_meta()
        |> ContactInvestigations.create()

      contact_investigation = contact_investigation |> ContactInvestigations.preload_exposed_person()

      person = contact_investigation.exposed_person

      Pages.Profile.visit(conn, person)
      |> Components.ContactInvestigation.assert_clinical_details(%{
        clinical_status: "None",
        exposed_on: "None",
        symptoms: "None"
      })
    end

    test "started contact investigations with a unknown clinical details render correctly", %{
      conn: conn,
      case_investigation: case_investigation
    } do
      {:ok, contact_investigation} =
        Test.Fixtures.contact_investigation_attrs(
          "contact_investigation",
          %{
            interview_started_at: NaiveDateTime.utc_now(),
            clinical_status: "unknown",
            exposing_case_id: case_investigation.id
          }
        )
        |> Test.Fixtures.wrap_with_audit_meta()
        |> ContactInvestigations.create()

      contact_investigation = contact_investigation |> ContactInvestigations.preload_exposed_person()

      person = contact_investigation.exposed_person

      Pages.Profile.visit(conn, person)
      |> Components.ContactInvestigation.assert_clinical_details(%{
        clinical_status: "Unknown"
      })
    end

    test "contact investigations with empty lists of symptoms show None for symptoms", %{
      conn: conn,
      case_investigation: case_investigation
    } do
      {:ok, contact_investigation} =
        Test.Fixtures.contact_investigation_attrs(
          "contact_investigation",
          %{
            interview_started_at: NaiveDateTime.utc_now(),
            symptoms: [],
            exposing_case_id: case_investigation.id
          }
        )
        |> Test.Fixtures.wrap_with_audit_meta()
        |> ContactInvestigations.create()

      contact_investigation = contact_investigation |> ContactInvestigations.preload_exposed_person()

      person = contact_investigation.exposed_person

      Pages.Profile.visit(conn, person)
      |> Components.ContactInvestigation.assert_clinical_details(%{
        symptoms: "None"
      })
    end
  end
end
