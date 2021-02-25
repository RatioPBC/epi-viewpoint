defmodule EpicenterWeb.Test.Pages.Profile do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Accounts.User
  alias Epicenter.Cases.Person
  alias Epicenter.Extra
  alias Epicenter.Test
  alias EpicenterWeb.Test.LiveViewAssertions
  alias EpicenterWeb.Test.Components
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %Person{id: person_id}, extra_arg \\ nil) do
    conn |> Pages.visit("/people/#{person_id}", extra_arg)
  end

  def assert_here(view_or_conn_or_html, person) do
    view_or_conn_or_html |> Pages.assert_on_page("profile")
    if !person.tid, do: raise("Person must have a tid for this assertion: #{inspect(person)}")
    view_or_conn_or_html |> Pages.parse() |> Test.Html.attr("[data-page=profile]", "data-tid") |> assert_eq([person.tid])
    view_or_conn_or_html
  end

  def click_edit_identifying_information(%View{} = view, conn) do
    view
    |> element("[data-role=edit-identifying-information-link]")
    |> render_click
    |> Pages.follow_live_view_redirect(conn)
  end

  def click_edit_demographics(%View{} = view, conn) do
    view
    |> element("[data-role=edit-demographics-link]")
    |> render_click
    |> Pages.follow_live_view_redirect(conn)
  end

  #
  # address
  #

  def assert_addresses(%View{} = view, ["Unknown"] = expected_addresses) do
    assert addresses(view, "span") == expected_addresses
    view
  end

  def assert_addresses(%View{} = view, expected_addresses) do
    assert addresses(view) == expected_addresses
    view
  end

  def addresses(%View{} = view, selector \\ "[data-role=address-details]") do
    view |> Pages.parse() |> Test.Html.all("[data-role=addresses] #{selector}", as: :text)
  end

  #
  # assigning
  #

  def assign(%View{} = view, %User{id: user_id}) do
    view |> element("#assignment-form") |> render_change(%{"user" => user_id})
    view
  end

  def unassign(%View{} = view) do
    view |> element("#assignment-form") |> render_change(%{"user" => "-unassigned-"})
    view
  end

  def assignable_users(%View{} = view) do
    view |> Pages.parse() |> Test.Html.all("[data-role=users] option", as: :text)
  end

  def assert_assignable_users(%View{} = view, expected_users) do
    assert assignable_users(view) == expected_users
    view
  end

  def assigned_user(%View{} = view) do
    view |> Pages.parse() |> Test.Html.text("[data-role=users] option[selected]")
  end

  def assert_assigned_user(%View{} = view, expected_user) do
    assert assigned_user(view) == expected_user
    view
  end

  #
  # date of birth
  #

  def assert_date_of_birth(%View{} = view, expected_dob) do
    assert view |> Pages.parse() |> Test.Html.text("[data-role=date-of-birth]") == expected_dob
    view
  end

  #
  # demographics
  #

  def assert_employment(%View{} = view, expected_status) do
    assert view |> Pages.parse() |> Test.Html.text("[data-role=employment]") == expected_status
    view
  end

  def assert_ethnicities(%View{} = view, expected_ethnicities) do
    assert view |> Pages.parse() |> Test.Html.all("[data-role=ethnicity] li", as: :text) |> assert_eq(expected_ethnicities, ignore_order: true)
    view
  end

  def assert_marital_status(%View{} = view, expected_status) do
    assert view |> Pages.parse() |> Test.Html.text("[data-role=marital-status]") == expected_status
    view
  end

  def assert_notes(%View{} = view, expected_notes) do
    assert view |> Pages.parse() |> Test.Html.text("[data-role=notes]") == expected_notes
    view
  end

  def assert_occupation(%View{} = view, expected_occupation) do
    assert view |> Pages.parse() |> Test.Html.text("[data-role=occupation]") == expected_occupation
    view
  end

  def assert_race(%View{} = view, expected_race) do
    view |> LiveViewAssertions.assert_role_list("race", expected_race)
  end

  def assert_sex_at_birth(%View{} = view, expected_sex_at_birth) do
    view |> Pages.parse() |> Test.Html.text("[data-role=sex-at-birth]") |> assert_eq(expected_sex_at_birth, returning: view)
  end

  #
  # email addresses
  #

  def assert_email_addresses(%View{} = view, ["Unknown"] = expected_email_addresses) do
    assert email_addresses(view, "span") == expected_email_addresses
    view
  end

  def assert_email_addresses(%View{} = view, expected_email_addresses) do
    assert email_addresses(view) == expected_email_addresses
    view
  end

  def email_addresses(%View{} = view, selector \\ "li") do
    view |> Pages.parse() |> Test.Html.all("[data-role=email-addresses] #{selector}", as: :text)
  end

  #
  # external id
  #

  def assert_external_id(%View{} = view, expected_external_id) do
    assert view |> Pages.parse() |> Test.Html.text("[data-role=external-id]") == expected_external_id
    view
  end

  #
  # full name
  #

  def assert_full_name(%View{} = view, expected_full_name) do
    assert view |> Pages.parse() |> Test.Html.text("[data-role=full-name]") == expected_full_name
    view
  end

  #
  # case investigations
  #

  def assert_case_investigations(%View{} = view, %{
        initiated_by: initiated_by,
        status: status,
        status_value: status_value,
        reported_on: reported_on,
        timestamp: timestamp
      }) do
    parsed_html = view |> render() |> Test.Html.parse()

    parsed_html |> Test.Html.text("[data-role=case-investigation-title]") |> String.trim() |> assert_eq("Case investigation #{reported_on}")
    parsed_html |> Test.Html.text("[data-role=case-investigation-initiated-by]") |> String.trim() |> assert_eq("Initiated by #{initiated_by}")
    parsed_html |> Test.Html.text("[data-role=case-investigation-interview-status] [data-role=status]") |> String.trim() |> assert_eq(status)
    parsed_html |> Test.Html.text("[data-role=case-investigation-timestamp]") |> String.trim() |> assert_eq("Created on #{timestamp}")

    assert parsed_html |> Test.Html.present?(selector: ".#{status_value}")

    view
  end

  def assert_no_case_investigations(%View{} = view) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("[data-role=case-investigation-title]")
    |> assert_eq([])

    view
  end

  def assert_potential_duplicates_button_present(%View{} = view, present?) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.present?(role: "view-potential-duplicates")
    |> assert_eq(present?)
  end

  def assert_start_interview_button_title(%View{} = view, number, title) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#start-interview-case-investigation-link-#{number}")
    |> Test.Html.text()
    |> assert_eq(title)

    view
  end

  def refute_start_interview_button(%View{} = view, number) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#start-interview-case-investigation-link-#{number}")
    |> assert_eq([])

    view
  end

  def assert_discontinue_interview_button_title(%View{} = view, number, title) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#discontinue-case-investigation-link-#{number}")
    |> Test.Html.text()
    |> assert_eq(title)

    view
  end

  def refute_discontinue_interview_button(%View{} = view, number) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#discontinue-case-investigation-link-#{number}")
    |> assert_eq([])

    view
  end

  def assert_case_investigation_complete_button_title(%View{} = view, number, title) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#complete-interview-case-investigation-link-#{number}")
    |> Test.Html.text()
    |> assert_eq(title)

    view
  end

  def refute_complete_interview_button(%View{} = view, number) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#complete-interview-case-investigation-link-#{number}")
    |> assert_eq([])

    view
  end

  def assert_case_investigation_has_history(%View{} = view, history_texts) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("[data-role=case-investigation-history-item-text]")
    |> Test.Html.text()
    |> assert_eq(history_texts)

    view
  end

  def assert_contact_investigation_has_history(%View{} = view, history_texts) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find!("[data-role=contact-investigation-history-item-text]")
    |> Test.Html.text()
    |> assert_eq(history_texts)

    view
  end

  def click_start_interview_case_investigation(%View{} = view, number) do
    view
    |> element("#start-interview-case-investigation-link-#{number}")
    |> render_click()
  end

  def click_discontinue_case_investigation(%View{} = view, number) do
    view
    |> element("#discontinue-case-investigation-link-#{number}")
    |> render_click()
  end

  def click_edit_discontinuation_link(%View{} = view, number) do
    view
    |> element("#edit-discontinue-case-investigation-link-#{number}")
    |> render_click()
  end

  def click_edit_complete_interview_link(%View{} = view, number) do
    view
    |> element("#edit-complete-interview-link-#{number}")
    |> render_click()
  end

  def click_edit_clinical_details_link(%View{} = view, number) do
    view
    |> element("#case-investigation-clinical-details-link-#{number}")
    |> render_click()
  end

  def click_edit_isolation_monitoring_link(%View{} = view, number) do
    view
    |> element("#edit-isolation-monitoring-link-#{number}")
    |> render_click()
  end

  def click_edit_isolation_order_details_link(%View{} = view, number) do
    view
    |> element("#edit-isolation-order-case-investigation-link-#{number}")
    |> render_click()
  end

  def click_edit_isolation_monitoring_conclusion_link(%View{} = view, number) do
    view
    |> element("#edit-isolation-monitoring-conclusion-link-#{number}")
    |> render_click()
  end

  def click_conclude_isolation_monitoring(%View{} = view, number) do
    view
    |> element("#conclude-isolation-monitoring-case-investigation-link-#{number}")
    |> render_click()
  end

  def click_complete_case_investigation(%View{} = view, number) do
    view
    |> element("#complete-interview-case-investigation-link-#{number}")
    |> render_click()
  end

  def click_view_potential_duplicates(%View{} = view) do
    view
    |> element("#view-potential-duplicates")
    |> render_click()
  end

  def refute_potential_duplicates(%View{} = view) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#view-potential-duplicates")
    |> assert_eq([])

    view
  end

  def case_investigation_notes(%View{} = view, number) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#case-investigation-#{number}")
    |> Components.InvestigationNote.note_content()
  end

  def assert_case_investigation_note_validation_messages(%View{} = view, number, messages) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#case-investigation-#{number} [data-role=note-form]")
    |> Test.Html.html()
    |> Pages.assert_validation_messages(messages)

    view
  end

  def add_case_investigation_note(%View{} = view, number, note_text) do
    view
    |> form("#case-investigation-#{number} [data-role=note-form]", %{"form_field_data" => %{"text" => note_text}})
    |> render_submit()

    view
  end

  def change_case_investigation_note_form(view, number, attrs) do
    view |> element("#case-investigation-#{number} [data-role=note-form]") |> render_change(form_field_data: attrs)
    view
  end

  # expected_values %{clinical_status: clinical_status, symptom_onset_on: symptom_onset_on}}
  def assert_clinical_details_showing(%View{} = view, number, expected_values) do
    parsed_html =
      view
      |> render()
      |> Test.Html.parse()

    parsed_html |> Test.Html.find!("#clinical-details-#{number}")

    with clinical_status when not is_nil(clinical_status) <- Map.get(expected_values, :clinical_status) do
      parsed_html
      |> Test.Html.find("[data-role=case-investigation-clinical-status-text]")
      |> Test.Html.text()
      |> assert_eq(clinical_status)
    end

    with symptom_onset_on when not is_nil(symptom_onset_on) <- Map.get(expected_values, :symptom_onset_on) do
      parsed_html
      |> Test.Html.find("[data-role=case-investigation-symptom-onset-date-text]")
      |> Test.Html.text()
      |> assert_eq(symptom_onset_on)
    end

    with symptoms when not is_nil(symptoms) <- Map.get(expected_values, :symptoms) do
      parsed_html
      |> Test.Html.find("[data-role=case-investigation-symptoms-text]")
      |> Test.Html.text()
      |> assert_eq(symptoms)
    end

    view
  end

  def assert_contacts_showing(%View{} = view, number) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find!("#contacts-#{number}")

    view
  end

  def assert_isolation_monitoring_visible(%View{} = view, %{status: status, number: number}) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.all("#isolation-monitoring-#{number} h3", as: :text)
    |> Enum.map(&Extra.String.squish/1)
    |> assert_eq([status])

    view
  end

  def assert_isolation_order_details(%View{} = view, number, %{
        order_sent_on: expected_order_sent_on,
        clearance_order_sent_on: expected_clearance_order_sent_on
      }) do
    parsed_html = view |> render() |> Test.Html.parse()

    parsed_html
    |> Test.Html.find("[data-tid=case-investigation-#{number}-isolation-order-sent-date]")
    |> Test.Html.text()
    |> assert_eq(expected_order_sent_on)

    parsed_html
    |> Test.Html.find("[data-tid=case-investigation-#{number}-isolation-clearance-order-sent-date]")
    |> Test.Html.text()
    |> assert_eq(expected_clearance_order_sent_on)

    view
  end

  def refute_clinical_details_showing(%View{} = view, number) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#clinical-details-#{number}")
    |> assert_eq([])

    view
  end

  def assert_isolation_monitoring_has_history(%View{} = view, history_texts) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("[data-role=isolation-monitoring-history-item-text]")
    |> Test.Html.text()
    |> assert_eq(history_texts)

    view
  end

  def refute_contacts_showing(%View{} = view, number) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#contacts-#{number}")
    |> assert_eq([])

    view
  end

  def refute_isolation_monitoring_visible(%View{} = view, number) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#isolation-monitoring-#{number}")
    |> assert_eq([])

    view
  end

  def case_investigation_contact_details(%View{} = view, number) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#contacts-#{number} .contact-details")
    |> Enum.map(&Test.Html.text/1)
  end

  def click_add_contact_link(%View{} = view, number) do
    view
    |> element("#add-contact-case-investigation-link-#{number}")
    |> render_click()
  end

  def click_add_place_link(%View{} = view, number) do
    view
    |> element("#add-place-link-#{number}")
    |> render_click()
  end

  def click_add_isolation_dates(%View{} = view, number) do
    view
    |> element("#add-isolation-dates-case-investigation-link-#{number}")
    |> render_click()
  end

  def click_edit_contact_link(%View{} = view, contact_investigation) do
    view
    |> element("[data-role=edit-contact][data-contact-investigation=#{contact_investigation.id}]")
    |> render_click()
  end

  def click_remove_contact_link(%View{} = view, contact_investigation) do
    view
    |> element("[data-role=remove-contact][phx-value-contact-investigation-id=#{contact_investigation.id}]")
    |> render_click()
  end

  def click_remove_visit_link(%View{} = view, visit) do
    view
    |> element("[data-role=remove-visit][phx-value-visit-id=#{visit.id}]")
    |> render_click()
  end

  def click_on_contact(%View{} = view, number, exposed_person_name) do
    view
    |> element("#contacts-#{number} [data-role=visit-contact-link]", exposed_person_name)
    |> render_click()
  end

  #
  # contact investigations
  #

  def add_contact_investigation_note(view, contact_investigation_tid, note_text) do
    view
    |> form("[data-tid=#{contact_investigation_tid}][data-role=contact-investigation] [data-role=note-form]", %{
      "form_field_data" => %{"text" => note_text}
    })
    |> render_submit()

    view
  end

  def click_on_exposing_case(%View{} = view, contact_investigation_tid) do
    view
    |> element("[data-tid=#{contact_investigation_tid}] [data-role=visit-exposing-case-link]")
    |> render_click()
  end

  def click_edit_interview_discontinuation_details(%View{} = view, contact_investigation_tid) do
    view
    |> element("[data-tid=#{contact_investigation_tid}] [data-role=contact-investigation-discontinue-interview-edit-link]")
    |> render_click()
  end

  def click_conclude_contact_investigation_quarantine_monitoring(%View{} = view, contact_investigation_tid) do
    view
    |> element("[data-tid=#{contact_investigation_tid}] [data-role=conclude-contact-investigation-quarantine-monitoring-link]")
    |> render_click()
  end

  def click_edit_conclude_contact_investigation_quarantine_monitoring(%View{} = view, contact_investigation_tid) do
    view
    |> element("[data-tid=#{contact_investigation_tid}] [data-role=conclude-contact-investigation-quarantine-monitoring-edit-link]")
    |> render_click()
  end

  def click_contact_investigation_complete_interview(%View{} = view, contact_investigation_tid) do
    view
    |> element("[data-tid=#{contact_investigation_tid}] [data-role=contact-investigation-complete-interview-link]")
    |> render_click()
  end

  def click_contact_investigation_quarantine_monitoring(%View{} = view, contact_investigation_tid) do
    view
    |> element("[data-tid=#{contact_investigation_tid}] [data-role=contact-investigation-quarantine-monitoring-start-link]")
    |> render_click()
  end

  def click_edit_contact_investigation_quarantine_monitoring(%View{} = view, contact_investigation_tid) do
    view
    |> element("[data-tid=#{contact_investigation_tid}] [data-role=edit-contact-investigation-quarantine-monitoring-link]")
    |> render_click()
  end

  def click_edit_contact_clinical_details_link(%View{} = view, contact_investigation_tid) do
    view
    |> element("[data-tid=#{contact_investigation_tid}] [data-role=edit-contact-clinical-details-link]")
    |> render_click()
  end

  def click_edit_interview_start_details(%View{} = view, contact_investigation_tid) do
    view
    |> element("[data-tid=#{contact_investigation_tid}] [data-role=contact-investigation-start-interview-edit-link]")
    |> render_click()
  end

  def click_edit_interview_completion_details(%View{} = view, contact_investigation_tid) do
    view
    |> element("[data-tid=#{contact_investigation_tid}] [data-role=contact-investigation-complete-interview-edit-link]")
    |> render_click()
  end

  def change_contact_investigation_note_form(view, contact_investigation_tid, attrs) do
    view |> element("[data-tid=#{contact_investigation_tid}] [data-role=note-form]") |> render_change(form_field_data: attrs)
    view
  end

  def contact_investigations(%View{} = view) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.all("[data-role=contact-investigation]", fn contact_investigation ->
      id = Test.Html.attr(contact_investigation, "data-contact-investigation-id") |> List.first()
      title = Test.Html.find(contact_investigation, "[data-role=contact-investigation-title]") |> Test.Html.text()
      creation_timestamp = Test.Html.find(contact_investigation, "[data-role=contact-investigation-timestamp]") |> Test.Html.text()
      initiating_case_text = Test.Html.find(contact_investigation, "[data-role=initiating-case]") |> Test.Html.text()

      minor_details =
        Test.Html.all(contact_investigation, "[data-role=minor-details] [data-role=detail]", fn detail ->
          Test.Html.text(detail)
        end)

      exposure_details =
        Test.Html.all(contact_investigation, "[data-role=contact-investigation-contact-investigation-details] [data-role=detail]", fn detail ->
          Test.Html.text(detail)
        end)

      interview_status = Test.Html.find(contact_investigation, "[data-role=contact-investigation-interview-status]") |> Test.Html.text()

      interview_buttons =
        Test.Html.all(contact_investigation, "[data-role=contact-investigation-interview-button]", fn detail ->
          Test.Html.text(detail)
        end)

      quarantine_monitoring_buttons =
        Test.Html.all(contact_investigation, "[data-role=contact-investigation-quarantine-buttons] > a", fn detail ->
          Test.Html.text(detail)
        end)

      interview_history_items =
        Test.Html.all(contact_investigation, "[data-role=contact-investigation-history-item-text]", fn detail ->
          Test.Html.text(detail)
        end)

      quarantine_status = Test.Html.find(contact_investigation, "[data-role=contact-investigation-quarantine-monitoring-status]") |> Test.Html.text()

      quarantine_history_items =
        Test.Html.all(contact_investigation, "[data-role=contact-investigation-quarantine-history-item-text]", fn item ->
          Test.Html.text(item)
        end)

      %{
        id: id,
        title: title,
        creation_timestamp: creation_timestamp,
        initiating_case_text: initiating_case_text,
        minor_details: minor_details,
        exposure_details: exposure_details,
        interview_status: interview_status,
        interview_buttons: interview_buttons,
        interview_history_items: interview_history_items,
        quarantine_status: quarantine_status,
        quarantine_monitoring_buttons: quarantine_monitoring_buttons,
        quarantine_history_items: quarantine_history_items
      }
    end)
  end

  def contact_investigation_notes(%View{} = view, contact_investigation_tid) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("[data-role=contact-investigation][data-tid=#{contact_investigation_tid}]")
    |> Components.InvestigationNote.note_content()
  end

  def click_discontinue_contact_investigation(%View{} = view, tid) do
    view
    |> element("[data-role=contact-investigation][data-tid=#{tid}] [data-role=contact-investigation-discontinue-interview]")
    |> render_click()
  end

  def click_start_contact_investigation(%View{} = view, tid) do
    view
    |> element("[data-role=contact-investigation][data-tid=#{tid}] [data-role=contact-investigation-start-interview]")
    |> render_click()
  end

  #
  # lab results
  #

  def assert_lab_results(%View{} = view, table_opts \\ [], expected) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Table.table_contents(Keyword.merge([role: "lab-result-table"], table_opts))
    |> assert_eq(expected)

    view
  end

  #
  # phone numbers
  #

  def assert_phone_numbers(%View{} = view, ["Unknown"] = expected_phone_numbers) do
    assert phone_numbers(view, "span") == expected_phone_numbers
    view
  end

  def assert_phone_numbers(%View{} = view, expected_phone_numbers) do
    assert phone_numbers(view) == expected_phone_numbers
    view
  end

  def phone_numbers(%View{} = view, selector \\ "li") do
    view |> Pages.parse() |> Test.Html.all("[data-role=phone-numbers] #{selector}", as: :text)
  end

  #
  # preferred language
  #

  def assert_preferred_language(%View{} = view, expected_preferred_language) do
    assert view |> Pages.parse() |> Test.Html.text("[data-role=preferred-language]") == expected_preferred_language
    view
  end

  #
  # Archiving
  #

  def assert_archived_banner_is_visible(%View{} = view, archiver_name, archived_date_str) do
    view
    |> Pages.parse()
    |> Test.Html.text("[data-role=archived-banner]")
    |> assert_eq("This record was archived on #{archived_date_str} by #{archiver_name}.Unarchive")

    view
  end

  def click_archive_button(%View{} = view) do
    view
    |> element("#archive")
    |> render_click()

    view
  end

  def click_unarchive_person_button(%View{} = view) do
    view
    |> element("#unarchive")
    |> render_click()

    view
  end

  def refute_archived_banner_is_visible(%View{} = view) do
    view
    |> Pages.parse()
    |> Test.Html.text("[data-role=archived-banner]")
    |> assert_eq("")

    view
  end

  def assert_visit(view, visit, is_visible: is_visible) do
    html =
      view
      |> Pages.parse()

    if is_visible do
      html |> Test.Html.find!("[data-tid=#{visit.tid}]")
    else
      html |> Test.Html.find("[data-tid=#{visit.tid}]") |> assert_eq([])
    end

    view
  end

  def assert_visit_address(view, case_investigation, name, address) do
    html =
      view
      |> Pages.parse()

    html |> Test.Html.text("[data-tid=#{case_investigation.tid}] [data-role=place-name]") |> assert_eq(name)
    html |> Test.Html.text("[data-tid=#{case_investigation.tid}] [data-role=place-address]") |> assert_eq(address)

    view
  end

  def assert_visit(view, case_investigation, place_type, relationship, phone, occurred_on) do
    html =
      view
      |> Pages.parse()

    html |> Test.Html.text("[data-tid=#{case_investigation.tid}] [data-role=place-type]") |> assert_eq(place_type)
    html |> Test.Html.text("[data-tid=#{case_investigation.tid}] [data-role=relationship]") |> assert_eq(relationship)
    html |> Test.Html.text("[data-tid=#{case_investigation.tid}] [data-role=contact-phone]") |> assert_eq(phone)
    html |> Test.Html.text("[data-tid=#{case_investigation.tid}] [data-role=occurred-on]") |> assert =~ occurred_on

    view
  end
end
