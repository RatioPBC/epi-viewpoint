defmodule EpicenterWeb.Test.Pages.PotentialDuplicates do
  import Euclid.Test.Extra.Assertions

  alias Epicenter.Cases.Person
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages

  def visit(%Plug.Conn{} = conn, %Person{id: person_id}, extra_arg \\ nil) do
    conn |> Pages.visit("/people/#{person_id}/potential-duplicates", extra_arg)
  end

  def assert_here(view_or_conn_or_html, person) do
    view_or_conn_or_html |> Pages.assert_on_page("potential-duplicates")
    if !person.tid, do: raise("Person must have a tid for this assertion: #{inspect(person)}")
    view_or_conn_or_html |> Pages.parse() |> Test.Html.attr("[data-page=potential-duplicates]", "data-tid") |> assert_eq([person.tid])
    view_or_conn_or_html
  end
end
