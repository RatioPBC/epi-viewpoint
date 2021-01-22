defmodule EpicenterWeb.Test.Pages.ResolveConflicts do
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
end
