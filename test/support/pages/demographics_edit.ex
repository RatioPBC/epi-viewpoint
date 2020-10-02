defmodule EpicenterWeb.Test.Pages.DemographicsEdit do
  import ExUnit.Assertions

  alias Epicenter.Cases.Person
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn, %Person{id: person_id}) do
    conn |> Pages.visit("/people/#{person_id}/edit-demographics")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("demographics-edit")
  end

  def assert_gender_identity_selections(view, expected_selections) do
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
  end
end
