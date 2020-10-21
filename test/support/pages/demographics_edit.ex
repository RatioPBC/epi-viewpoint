defmodule EpicenterWeb.Test.Pages.DemographicsEdit do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Cases.Person
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  def visit(%Plug.Conn{} = conn, %Person{id: person_id}) do
    conn |> Pages.visit("/people/#{person_id}/edit-demographics")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("demographics-edit")
  end

  def assert_gender_identity_selections(%View{} = view, expected_selections) do
    actual_selections =
      view
      |> Pages.parse()
      |> Test.Html.all(
        "[data-role=gender-identity-checkbox-label]",
        fn element ->
          {
            Test.Html.text(element),
            Test.Html.attr(element, "input[type=checkbox]", "checked") == ["checked"]
          }
        end
      )
      |> Map.new()

    assert actual_selections == expected_selections
    view
  end

  def assert_major_ethnicity_selection(%View{} = view, expected_selections) do
    assert actual_selections(view, "major-ethnicity-label", "radio") == expected_selections
    view
  end

  def assert_detailed_ethnicity_selections(%View{} = view, expected_selections) do
    assert actual_selections(view, "detailed-ethnicity-label", "checkbox") == expected_selections
    view
  end

  def assert_major_ethnicity_selected(%View{} = view, expected_major_ethnicity) do
    actual_selected_major_ethnicity =
      view
      |> actual_selections("major-ethnicity-label", "radio")
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
      view |> actual_selections("detailed-ethnicity-label", "checkbox") |> Enum.filter(fn {_, value} -> value end)

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
    assert actual_selections(view, "marital-status-label", "radio") == expected_marital_statuses
    view
  end

  def assert_notes(%View{} = view, expected_notes) do
    assert view |> Pages.parse() |> Test.Html.text("[data-role=notes-input]") |> String.trim_leading() == expected_notes
    view
  end

  def assert_occupation(%View{} = view, occupation) do
    assert view |> Pages.parse() |> Test.Html.attr("[data-role=occupation-input]", "value") |> Euclid.Extra.List.first("") == occupation
    view
  end

  def actual_selections(%View{} = view, data_role, type) do
    view
    |> Pages.parse()
    |> Test.Html.all(
      "[data-role=#{data_role}]",
      fn element ->
        {
          Test.Html.text(element),
          Test.Html.attr(element, "input[type=#{type}]", "checked") == ["checked"]
        }
      end
    )
    |> Map.new()
  end

  def change_form(%View{} = view, person_params) do
    view
    |> form("#demographics-form", person: person_params)
    |> render_change()

    view
  end
end
