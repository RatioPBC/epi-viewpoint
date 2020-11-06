defmodule EpicenterWeb.Test.Pages.Profile do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Accounts.User
  alias Epicenter.Cases.Person
  alias Epicenter.Test
  alias Epicenter.Test.HtmlAssertions
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

  def assert_major_ethnicity(%View{} = view, expected_major_ethnicity) do
    assert view |> Pages.parse() |> Test.Html.text("[data-role=major-ethnicity]") == expected_major_ethnicity
    view
  end

  def assert_detailed_ethnicities(%View{} = view, expected_detailed_ethniticies) do
    assert view |> Pages.parse() |> Test.Html.all("[data-role=detailed-ethnicity]", as: :text) == expected_detailed_ethniticies
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
  # full name
  #

  def assert_full_name(%View{} = view, expected_full_name) do
    assert view |> Pages.parse() |> Test.Html.text("[data-role=full-name]") == expected_full_name
    view
  end

  #
  # case investigations
  #

  def assert_case_investigations(%View{} = view, %{status: status, status_value: status_value, reported_on: reported_on, number: number}) do
    parsed_html =
      view
      |> render()
      |> Test.Html.parse()

    parsed_html
    |> HtmlAssertions.assert_text("status", status)
    |> HtmlAssertions.assert_text("reported-on", reported_on)
    |> HtmlAssertions.assert_text("case-investigation-title", number)

    assert parsed_html
           |> Test.Html.present?(selector: ".#{status_value}")

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

  def click_edit_clinical_details_link(%View{} = view, number) do
    view
    |> element("#case-investigation-clinical-details-link-#{number}")
    |> render_click()
  end

  def click_complete_case_investigation(%View{} = view, number) do
    view
    |> element("#complete-interview-case-investigation-link-#{number}")
    |> render_click()
  end

  # expected_values %{clinical_status: clinical_status, symptom_onset_date: symptom_onset_date}}
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

    with symptom_onset_date when not is_nil(symptom_onset_date) <- Map.get(expected_values, :symptom_onset_date) do
      parsed_html
      |> Test.Html.find("[data-role=case-investigation-symptom-onset-date-text]")
      |> Test.Html.text()
      |> assert_eq(symptom_onset_date)
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

  def refute_clinical_details_showing(%View{} = view, number) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#clinical-details-#{number}")
    |> assert_eq([])

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

  def case_investigation_contact_details(%View{} = view, number) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("#contacts-#{number} .contact-details")
    |> Enum.map(&Test.Html.text/1)
  end

  #
  # lab results
  #

  def assert_lab_results(%View{} = view, table_opts \\ [], expected) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Table.table_contents(Keyword.merge([role: "lab-result-table"], table_opts))
    |> assert_eq(expected, :simple)

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
end
