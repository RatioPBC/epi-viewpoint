defmodule EpicenterWeb.Test.LiveViewAssertions do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test

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

    if has_element?(view, selector, expected_value) do
      true
    else
      """
      Expected to find element with selector “#{selector}” and text “#{expected_value}”, but found:

        #{view |> element(selector) |> render()}
      """
      |> flunk()
    end
  end
end
