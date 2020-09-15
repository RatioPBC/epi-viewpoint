defmodule EpicenterWeb.Test.LiveViewAssertions do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test

  def assert_attribute(view, data_role, attribute, expected) do
    selector = "[data-role=#{data_role}]"
    rendered = view |> element(selector) |> render()

    if rendered |> Test.Html.parse_doc() |> Floki.attribute(attribute) == expected do
      true
    else
      """
      Expected to find element with data-role “#{data_role}” with attribute “#{attribute}” as “#{expected}”, but found:

        #{rendered}
      """
      |> flunk()
    end
  end

  def assert_checked(%Phoenix.LiveViewTest.View{} = view, data_role) do
    assert_attribute(view, data_role, "checked", ["checked"])
  end

  def assert_unchecked(%Phoenix.LiveViewTest.View{} = view, data_role) do
    assert_attribute(view, data_role, "checked", [])
  end

  def assert_disabled(%Phoenix.LiveViewTest.View{} = view, data_role) do
    assert_attribute(view, data_role, "disabled", ["disabled"])
  end

  def assert_enabled(%Phoenix.LiveViewTest.View{} = view, data_role) do
    assert_attribute(view, data_role, "disabled", [])
  end

  def assert_has_role(%Phoenix.LiveViewTest.View{} = view, data_role) do
    if has_element?(view, "[data-role=#{data_role}]") do
      view
    else
      """
      Expected to find element with data-role “#{data_role}” in:

        #{render(view)}
      """
      |> flunk()
    end
  end

  def assert_has_role(html, data_role) when is_binary(html) do
    if html |> Test.Html.parse_doc() |> Test.Html.has_role?(data_role) do
      html
    else
      """
      Expected to find element with data-role “#{data_role}” in:

        #{html}
      """
      |> flunk()
    end
  end

  def assert_role_text(%Phoenix.LiveViewTest.View{} = view, data_role, expected_value) do
    selector = "[data-role=#{data_role}]"
    rendered = view |> element(selector) |> render() |> Test.Html.parse() |> Test.Html.text()

    if rendered == expected_value do
      true
    else
      """
      Expected to find element with data-role “#{data_role}” and text “#{expected_value}”, but found:

        #{rendered}
      """
      |> flunk()
    end
  end

  def assert_select_dropdown_options(view: %Phoenix.LiveViewTest.View{} = view, data_role: data_role, expected: expected_values) do
    rendered = view |> render() |> Test.Html.parse_doc() |> Floki.find("[data-role=#{data_role}] option") |> Enum.map(&Test.Html.text(&1))

    if rendered == expected_values do
      true
    else
      """
      Expected to find element with data-role “#{data_role}” and options “#{inspect(expected_values)}”, but found:

        #{inspect(rendered)}
      """
      |> flunk()
    end
  end

  def assert_selected_dropdown_option(view: %Phoenix.LiveViewTest.View{} = view, data_role: data_role, expected: expected_value) do
    rendered = view |> render() |> Test.Html.parse_doc() |> Floki.find("[data-role=#{data_role}] option[selected]") |> Enum.map(&Test.Html.text(&1))

    if rendered == expected_value do
      true
    else
      """
      Expected to find element with data-role “#{data_role}” and options “#{inspect(expected_value)}”, but found:

        #{inspect(rendered)}
      """
      |> flunk()
    end
  end
end
