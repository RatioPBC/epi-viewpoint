defmodule EpicenterWeb.Test.Components.InvestigationNote do
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias Epicenter.Test
  alias Phoenix.LiveViewTest.View

  @spec delete_note(%View{}, String.t()) :: :ok | :note_not_found | :delete_button_not_found
  def delete_note(%View{} = view, note_id) do
    view
    |> render()
    |> Test.Html.parse()
    |> Test.Html.find("[data-note-id=#{note_id}] [data-role=delete-note]")
    |> length()
    |> case do
      1 ->
        view
        |> element("[data-note-id=#{note_id}] [data-role=delete-note]")
        |> render_click()

        :ok

      0 ->
        :delete_button_not_found

      _ ->
        flunk("too many delete buttons")
    end
  end

  def note_content(%View{} = view) do
    view
    |> render()
    |> Test.Html.parse()
    |> note_content()
  end

  def note_content(html) do
    html
    |> Test.Html.all("[data-role=investigation-note]", fn note_el ->
      id = Test.Html.attr(note_el, "data-note-id") |> List.first()
      text = Test.Html.find(note_el, "[data-role=investigation-note-text]") |> Test.Html.text()
      author = Test.Html.find(note_el, "[data-role=investigation-note-author]") |> Test.Html.text()
      date = Test.Html.find(note_el, "[data-role=investigation-note-date]") |> Test.Html.text()
      %{id: id, text: text, author: author, date: date}
    end)
  end
end
