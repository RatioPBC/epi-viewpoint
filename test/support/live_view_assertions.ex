defmodule EpicenterWeb.Test.LiveViewAssertions do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

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
