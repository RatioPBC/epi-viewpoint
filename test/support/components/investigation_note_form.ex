defmodule EpiViewpointWeb.Test.Components.InvestigationNoteForm do
  import Phoenix.LiveViewTest

  alias Phoenix.LiveViewTest.View

  def change_note(%View{} = view, text) do
    view
    |> element("form[data-role=note-form]")
    |> render_change(%{"form_field_data" => %{"text" => text}})
  end

  def submit_new_note(%View{} = view, text) do
    view
    |> element("form[data-role=note-form]")
    |> render_submit(%{"form_field_data" => %{"text" => text}})
  end
end
