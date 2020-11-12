defmodule EpicenterWeb.Test.Pages.DemographicsEdit do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Cases.Person
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %Person{id: person_id}) do
    conn |> Pages.visit("/people/#{person_id}/edit-demographics")
  end

  def assert_employment_selections(%View{} = view, expected_employment_statuses) do
    assert Pages.actual_selections(view, "demographic-form-employment", "radio") == expected_employment_statuses
    view
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("demographics-edit")
  end

  def assert_gender_identity_selections(%View{} = view, expected_selections) do
    assert Pages.actual_selections(view, "demographic-form-gender-identity", ["checkbox", "radio", "text"]) == expected_selections
    view
  end

  def assert_gender_identity_other(%View{} = view, expected) do
    view
    |> Pages.parse()
    |> Test.Html.attr("[data-role=demographic-form-gender-identity] input[type=text]", "value")
    |> assert_eq([expected], returning: view)
  end

  def assert_major_ethnicity_selection(%View{} = view, expected_selections) do
    assert Pages.actual_selections(view, "demographic-form-ethnicity", ["checkbox", "radio"]) == expected_selections
    view
  end

  def assert_detailed_ethnicity_selections(%View{} = view, expected_selections) do
    assert Pages.actual_selections(view, "demographic-form-ethnicity-hispanic-latinx-or-spanish-origin", ["checkbox", "radio"]) == expected_selections
    view
  end

  def assert_major_ethnicity_selected(%View{} = view, expected_major_ethnicity) do
    actual_selected_major_ethnicity =
      view
      |> Pages.actual_selections("demographic-form-ethnicity", "radio")
      |> Enum.filter(fn {_, value} -> value end)

    if actual_selected_major_ethnicity != [{expected_major_ethnicity, true}] do
      actual_selected_major_ethnicity = actual_selected_major_ethnicity |> Enum.into([], &Kernel.elem(&1, 0))

      """
      Expected to only find major ethnicity “#{expected_major_ethnicity}” selected, but found:
        #{inspect(actual_selected_major_ethnicity)}
      """
      |> flunk()
    end

    view
  end

  def assert_detailed_ethnicities_selected(%View{} = view, expected_detailed_ethnicities) do
    expected_detailed_ethnicities_tuple = expected_detailed_ethnicities |> Enum.into([], &{&1, true})

    actual_selected_detailed_ethnicities =
      view |> Pages.actual_selections("detailed-ethnicity-label", "checkbox") |> Enum.filter(fn {_, value} -> value end)

    if actual_selected_detailed_ethnicities != expected_detailed_ethnicities_tuple do
      actual_selected_detailed_ethnicities = actual_selected_detailed_ethnicities |> Enum.into([], &Kernel.elem(&1, 0))

      """
      Expected to find detailed ethnicities “#{inspect(expected_detailed_ethnicities)}” selected, but found:
        #{inspect(actual_selected_detailed_ethnicities)}
      """
      |> flunk()
    end

    view
  end

  def assert_marital_status_selection(%View{} = view, expected_marital_statuses) do
    assert Pages.actual_selections(view, "demographic-form-marital-status", "radio") == expected_marital_statuses
    view
  end

  def assert_notes(%View{} = view, expected_notes) do
    assert view |> Pages.parse() |> Test.Html.text(~s|textarea[name="demographic_form[notes]"]|) |> String.trim_leading() == expected_notes
    view
  end

  def assert_occupation(%View{} = view, occupation) do
    assert view |> Pages.parse() |> Test.Html.attr(~s|input[name="demographic_form[occupation]"]|, "value") |> Euclid.Extra.List.first("") ==
             occupation

    view
  end

  def change_form(%View{} = view, person_params) do
    view
    |> form("#demographics-form", demographic_form: person_params)
    |> render_change()

    view
  end
end
