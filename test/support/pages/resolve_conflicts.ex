defmodule EpicenterWeb.Test.Pages.ResolveConflicts do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Extra
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn, person_ids) do
    query_string = Enum.join(person_ids, ",")
    conn |> Pages.visit("/resolve-conflicts?person_ids=#{query_string}")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("resolve-conflicts")
    view_or_conn_or_html
  end

  def assert_person_present(view, person) do
    if !person.tid, do: raise("Person must have a tid for this assertion: #{inspect(person)}")

    view
    |> Pages.parse()
    |> Test.Html.find!("[data-tid=#{person.tid}]")

    view
  end

  def assert_save_button_enabled(view, enabled?) do
    expected = if enabled?, do: [], else: ["disabled"]
    view |> Pages.parse() |> Test.Html.attr("[data-role=save-button]", "disabled") |> assert_eq(expected, returning: view)
  end

  def assert_unique_values_present(view, field_name, values) do
    role = ["resolve-conflicts-form", field_name] |> Extra.String.dasherize()
    assert view |> Pages.parse() |> Test.Html.role_texts(role) |> Enum.sort() == values |> Enum.sort()
    view
  end

  def assert_no_conflicts_for_field(view, field_name) do
    role = ["resolve-conflicts-form", field_name] |> Extra.String.dasherize()
    assert view |> Pages.parse() |> Test.Html.all("[data-role=#{role}]", as: :text) == []
  end

  def click_first_name(view, name) do
    view |> element("[data-role=resolve-conflicts-form]") |> render_change(%{resolve_conflicts_form: %{first_name: name}})
    view
  end
end
