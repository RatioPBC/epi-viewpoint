defmodule EpicenterWeb.Test.Pages do
  @endpoint EpicenterWeb.Endpoint

  import Euclid.Test.Extra.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias Phoenix.LiveViewTest.View

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

  def follow_live_view_redirect(redirect_response, conn) do
    follow_redirect(redirect_response, conn)
  end

  def parse(%Plug.Conn{} = conn),
    do: conn |> html_response(200) |> Test.Html.parse_doc()

  def parse(%View{} = view),
    do: view |> render() |> Test.Html.parse()

  def parse(html_string) when is_binary(html_string),
    do: html_string |> Test.Html.parse_doc()

  def submit_form(%Plug.Conn{} = conn, role, name, %{} = fields) do
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

    conn |> Phoenix.ConnTest.post(path, %{name => fields}) |> follow_conn_redirect()
  end

  def visit(%Plug.Conn{} = conn, path) do
    {:ok, view, _html} = live(conn, path)
    view
  end

  def visit(%Plug.Conn{} = conn, path, :follow_redirect) do
    conn
    |> live(path)
    |> follow_live_view_redirect(conn)
    |> case do
      {:ok, %View{} = view, _html} -> view
      {:ok, conn} -> conn
    end
  end
end
