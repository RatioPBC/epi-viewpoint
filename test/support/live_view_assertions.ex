defmodule EpicenterWeb.Test.LiveViewAssertions do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test

  def assert_is_checked(%Phoenix.LiveViewTest.View{} = view, data_tid) do
    assert_checkbox(view, data_tid, ["checked"], "with")
  end

  def assert_is_not_checked(%Phoenix.LiveViewTest.View{} = view, data_tid) do
    assert_checkbox(view, data_tid, [], "without")
  end

  def assert_is_disabled(%Phoenix.LiveViewTest.View{} = view, data_role) do
    selector = "[data-role=#{data_role}]"
    rendered = view |> element(selector) |> render()

    if rendered |> Test.Html.parse_doc() |> Floki.attribute("data-disabled") == ["true"] do
      true
    else
      """
      Expected to find element with data-role “#{data_role}” with data-disabled="true", but found:

        #{rendered}
      """
      |> flunk()
    end
  end

  def assert_is_enabled(%Phoenix.LiveViewTest.View{} = view, data_role) do
    selector = "[data-role=#{data_role}]"
    rendered = view |> element(selector) |> render()

    if rendered |> Test.Html.parse_doc() |> Floki.attribute("data-disabled") == ["false"] do
      true
    else
      """
      Expected to find element with data-role “#{data_role}” with data-disabled="false", but found:

        #{rendered}
      """
      |> flunk()
    end
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

  # # #

  defp assert_checkbox(view, tid, expected, with_or_without) do
    selector = "[data-tid=#{tid}]"
    rendered = view |> element(selector) |> render()

    if rendered |> Test.Html.parse_doc() |> Floki.attribute("checked") == expected do
      true
    else
      """
      Expected to find element with data-tid “#{tid}” #{with_or_without} attribute “checked”, but found:

        #{rendered}
      """
      |> flunk()
    end
  end
end
