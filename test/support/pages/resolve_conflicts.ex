defmodule EpicenterWeb.Test.Pages.ResolveConflicts do
  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Extra
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn, person_id, duplicate_person_ids) do
    query_string = Enum.join(duplicate_person_ids, ",")
    conn |> Pages.visit("/people/#{person_id}/resolve-conflicts?duplicate_person_ids=#{query_string}")
  end

  def assert_here(view_or_conn_or_html) do
    view_or_conn_or_html |> Pages.assert_on_page("resolve-conflicts")
    view_or_conn_or_html
  end

  def assert_first_names_present(view, first_names) do
    text =
      view
      |> Pages.parse()
      |> Test.Html.find!("[data-role=resolve-conflicts-form-first-name]")
      |> Test.Html.text()

    Enum.each(first_names, &assert(text =~ &1))

    view
  end

  def assert_message(view, expected_message) do
    view |> Pages.parse() |> Test.Html.text(role: "merge-message") |> assert_eq(expected_message, returning: view)
  end

  def assert_merge_button_enabled(view, enabled?) do
    expected = if enabled?, do: [], else: ["disabled"]
    view |> Pages.parse() |> Test.Html.attr("[data-role=merge-button]", "disabled") |> assert_eq(expected, returning: view)
  end

  def assert_unique_values_present(view, field_name, values) do
    role = ["resolve-conflicts-form", field_name] |> Extra.String.dasherize()
    assert view |> Pages.parse() |> Test.Html.role_texts(role) |> Enum.sort() == values |> Enum.sort()
    view
  end

  def assert_no_conflicts(view) do
    refute view |> Pages.parse() |> Test.Html.present?(selector: "form[data-role=resolve-conflicts-form] input[type=radio]")
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
