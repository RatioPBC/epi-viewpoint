defmodule EpicenterWeb.Test.Pages do
  @endpoint EpicenterWeb.Endpoint

  import Euclid.Test.Extra.Assertions
  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias Phoenix.LiveViewTest.View

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
    |> assert_eq(data_page_value, :simple)

    conn_or_view_or_html
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

  def follow_live_view_redirect(redirect_response, conn),
    do: follow_redirect(redirect_response, conn)

  def form_errors(conn),
    do: conn |> parse() |> Test.Html.all("[data-form-error-message]", attr: "data-form-error-message")

  def parse(%Plug.Conn{} = conn),
    do: conn |> html_response(200) |> Test.Html.parse_doc()

  def parse(%View{} = view),
    do: view |> render() |> Test.Html.parse()

  def parse(html_string) when is_binary(html_string),
    do: html_string |> Test.Html.parse_doc()

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
    {:ok, view, _} =
      view
      |> form(form_selector, params_keyword_list)
      |> render_submit()
      |> follow_live_view_redirect(conn)

    view
  end

  def visit(conn, path, option \\ nil)

  def visit(%Plug.Conn{} = conn, path, :follow_redirect) do
    conn
    |> live(path)
    |> follow_live_view_redirect(conn)
    |> case do
      {:ok, %View{} = view, _html} -> view
      {:ok, conn} -> conn
    end
  end

  def visit(%Plug.Conn{} = conn, path, :notlive) do
    conn |> get(path)
  end

  def visit(%Plug.Conn{} = conn, path, nil) do
    {:ok, view, _html} = live(conn, path)
    view
  end
end
