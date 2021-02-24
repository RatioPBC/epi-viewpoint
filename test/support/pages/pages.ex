defmodule EpicenterWeb.Test.Pages do
  @endpoint EpicenterWeb.Endpoint

  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias Phoenix.LiveViewTest.View

  def actual_selections(%View{} = view, data_role, type) do
    input_selector = type |> List.wrap() |> Enum.map(&"input[type=#{&1}]") |> Enum.join(", ")

    view
    |> parse()
    |> Test.Html.all(
      "[data-role=#{data_role}]",
      fn element ->
        {
          Test.Html.text(element),
          Test.Html.attr(element, input_selector, "checked") == ["checked"]
        }
      end
    )
    |> Map.new()
  end

  def refute_confirmation_prompt_active(%View{} = view) do
    refute has_element?(view, "[data-confirm-navigation]")
    view
  end

  def assert_confirmation_prompt_active(%View{} = view, expected_text) do
    confirmation_prompts =
      view
      |> parse()
      |> Test.Html.find("[data-confirm-navigation]")
      |> Test.Html.attr("data-confirm-navigation")
      |> Enum.map(fn confirmation_text ->
        assert Euclid.Exists.present?(confirmation_text)
        assert expected_text == confirmation_text
      end)

    assert length(confirmation_prompts) > 0

    view
  end

  def assert_element_triggers_confirmation_prompt(%View{} = view, element_role, expected_text) do
    view
    |> parse()
    |> Test.Html.attr("[data-role=#{element_role}]", "data-confirm")
    |> assert_eq([expected_text])

    view
  end

  def assert_current_user(conn_or_view_or_html, user_name) do
    conn_or_view_or_html |> parse() |> Test.Html.role_text("current-user-name") |> assert_eq(user_name)
    conn_or_view_or_html
  end

  def assert_form_errors({:error, conn, errors}, expected_errors) do
    assert errors == expected_errors
    conn
  end

  def assert_form_errors(conn_or_view_or_html, expected_errors) do
    assert form_errors(conn_or_view_or_html) == expected_errors
    conn_or_view_or_html
  end

  def assert_on_page(conn_or_view_or_html, data_page_value) do
    conn_or_view_or_html
    |> parse()
    |> Test.Html.find!("[data-page]")
    |> Test.Html.attr("data-page")
    |> List.first()
    |> assert_eq(data_page_value)

    conn_or_view_or_html
  end

  def assert_redirect_succeeded({:error, {:live_redirect, _opts}} = response), do: response

  def assert_redirect_succeeded(conn_or_view_or_html) do
    assert_form_errors(conn_or_view_or_html, []) || flunk("Expected a redirect")
  end

  def assert_validation_messages(%View{} = view, expected_messages) do
    view |> render() |> assert_validation_messages(expected_messages)
    view
  end

  def assert_validation_messages(view_or_html_string, expected_messages) do
    view_or_html_string
    |> validation_messages()
    |> assert_eq(expected_messages)
  end

  def validation_messages(%View{} = view) do
    view |> render() |> validation_messages()
  end

  def validation_messages(html_string) when is_binary(html_string) do
    document = html_string |> Test.Html.parse()

    document
    |> Test.Html.all("[phx-feedback-for]", fn validation_message ->
      id = Test.Html.attr(validation_message, "phx-feedback-for") |> List.first()
      name = Test.Html.find!(document, "[id^=#{id}]") |> Test.Html.attr("name") |> List.first()
      {name, Test.Html.text(validation_message)}
    end)
    |> Enum.into(%{})
  end

  def assert_save_error(%View{} = view, expected_message) do
    assert actual_save_error(view) == expected_message
    view
  end

  def follow_conn_redirect(conn, max_directs \\ 10)

  def follow_conn_redirect(%Plug.Conn{} = _conn, 0 = _max_redirects),
    do: raise("Too many redirects")

  def follow_conn_redirect(%Plug.Conn{status: status} = conn, max_redirects) when status in [301, 302] do
    [new_location] = conn |> Plug.Conn.get_resp_header("location")
    conn |> Phoenix.ConnTest.get(new_location) |> follow_conn_redirect(max_redirects - 1)
  end

  def follow_conn_redirect(%Plug.Conn{} = conn, _),
    do: conn

  def follow_live_view_redirect(redirect_response, conn) do
    follow_redirect(redirect_response, conn) |> elem(1)
  end

  def form_errors(conn),
    do: conn |> parse() |> Test.Html.all("[data-form-error-message]", attr: "data-form-error-message")

  def form_labels(%View{} = view) do
    parsed =
      view
      |> render()
      |> Test.Html.parse()

    parsed
    |> Test.Html.all("label[for]:not([type=radio])", fn label ->
      html_for = label |> Test.Html.attr("for") |> List.first()

      with input when not is_nil(input) <- Test.Html.find(parsed, "##{html_for}") do
        name = input |> Test.Html.attr("name") |> List.first()
        text = label |> Test.Html.text()
        {name, text}
      else
        _ -> nil
      end
    end)
    |> Enum.concat(
      parsed
      |> Test.Html.all("[type=radio]", attr: "name")
      |> Enum.uniq()
      |> Enum.map(fn radio_input_name ->
        {radio_input_name, radio_options(view, radio_input_name) |> Enum.map(& &1.label)}
      end)
    )
    |> Enum.into(%{})
  end

  def radio_options(view, input_name) do
    document =
      view
      |> render()
      |> Test.Html.parse()

    document
    |> Test.Html.all("[type=radio][name='#{input_name}']", fn element ->
      value = Test.Html.attr(element, "value") |> List.first()
      id = Test.Html.attr(element, "id") |> List.first()

      parent_label =
        Test.Html.all(document, "label", fn label ->
          label
        end)
        |> Enum.reject(fn label ->
          Test.Html.find(label, "##{id}") |> Euclid.Exists.blank?()
        end)
        |> List.first()

      id_match_label = document |> Test.Html.find("[for=#{id}]")

      label =
        with label when not is_nil(label) <- parent_label || id_match_label do
          label |> Test.Html.text()
        else
          _ -> nil
        end

      %{
        value: value,
        label: label
      }
    end)
    |> Enum.reject(&Euclid.Exists.blank?/1)
  end

  def form_state(%View{} = view) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.all("[name]", fn thing -> thing end)
    |> Enum.filter(fn
      {tag, _attrs, _children} when tag in ["select", "textarea"] ->
        true

      {"input", _attrs, _children} = element ->
        type = element |> Test.Html.attr("type") |> List.first()
        checked = element |> Test.Html.attr("checked") |> List.first()
        type not in ["radio", "checkbox"] || checked == "checked"

      _ ->
        false
    end)
    |> Enum.reduce(%{}, fn
      {"textarea", _attrs, _children} = element, acc ->
        acc
        |> Map.put(
          Test.Html.attr(element, "name") |> List.first(),
          Test.Html.text(element)
        )

      {"select", _attrs, _children} = element, acc ->
        acc
        |> Map.put(
          Test.Html.attr(element, "name") |> List.first(),
          Test.Html.find(element, "option[selected]") |> Test.Html.attr("value") |> List.first()
        )

      element, acc ->
        acc |> Map.put(Test.Html.attr(element, "name") |> List.first(), Test.Html.attr(element, "value") |> List.first() |> Kernel.||(""))
    end)
  end

  def parse(%Plug.Conn{} = conn),
    do: conn |> html_response(200) |> Test.Html.parse_doc()

  def parse(%View{} = view),
    do: view |> render() |> Test.Html.parse()

  def parse(html_string) when is_binary(html_string),
    do: html_string |> Test.Html.parse_doc()

  def refute_save_error(%View{} = view) do
    assert actual_save_error(view) == ""
    view
  end

  def submit_form(%Plug.Conn{} = conn, http_method, role, name, %{} = fields)
      when http_method in [:put, :post] do
    form = conn |> parse() |> Test.Html.find!("[data-role=#{role}]")
    [path] = form |> Test.Html.attr("action")
    requested_fields = fields |> Enum.map(fn {k, v} -> {Phoenix.HTML.Form.input_name(name, k), v} end) |> Map.new()
    requested_field_names = requested_fields |> Map.keys() |> MapSet.new()
    actual_field_names = form |> Test.Html.all("input", attr: "name") |> MapSet.new()

    if !MapSet.subset?(requested_field_names, actual_field_names) do
      raise """
      Form with data-role “#{role}” does not have requested fields.
      requested: #{inspect(requested_field_names |> MapSet.to_list())}
      actual: #{inspect(actual_field_names |> MapSet.to_list())}
      """
    end

    conn =
      conn
      |> Phoenix.ConnTest.dispatch(@endpoint, http_method, path, %{name => fields})
      |> follow_conn_redirect()

    case form_errors(conn) do
      [] -> conn
      errors -> {:error, conn, errors}
    end
  end

  def submit_and_follow_redirect(%View{} = view, conn, form_selector, params_keyword_list) do
    view
    |> form(form_selector, params_keyword_list)
    |> render_submit()
    |> assert_redirect_succeeded()
    |> follow_live_view_redirect(conn)
  end

  def submit_expecting_error(%View{} = view, form_selector, params_keyword_list) do
    view
    |> form(form_selector, params_keyword_list)
    |> render_submit()
  end

  def submit_live(%View{} = view, form_selector, params_keyword_list) do
    view
    |> form(form_selector, params_keyword_list)
    |> render_submit()

    view
  end

  def visit(conn, path, option \\ nil)

  def visit(%Plug.Conn{} = conn, path, :follow_redirect) do
    conn
    |> live(path)
    |> follow_live_view_redirect(conn)
  end

  def visit(%Plug.Conn{} = conn, path, :notlive) do
    conn |> get(path)
  end

  def visit(%Plug.Conn{} = conn, path, nil) do
    {:ok, view, _html} = live(conn, path)
    view
  end

  # # #

  defp actual_save_error(view) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.text(".form-error-message")
  end
end
