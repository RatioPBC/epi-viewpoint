defmodule EpiViewpointWeb.Test.Pages.ContactInvestigationDiscontinue do
  alias EpiViewpoint.Test
  alias EpiViewpointWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  import Phoenix.LiveViewTest

  def visit(conn, contact_investigation) do
    conn |> Pages.visit("/contact-investigations/#{contact_investigation.id}/discontinue")
  end

  def assert_here(%View{} = view, contact_investigation) do
    view
    |> render()
    |> Pages.parse()
    |> Test.Html.find!("[data-role=contact-investigation-discontinue-page][data-contact-investigation-id=#{contact_investigation.id}]")

    view
  end

  def change_form(%View{} = view, attrs) do
    view
    |> form("#contact-investigation-discontinue-form", attrs)
    |> render_change()

    view
  end

  def form_title(%View{} = view) do
    view
    |> render()
    |> Pages.parse()
    |> Test.Html.find!(".InvestigationDiscontinueForm [data-role=form-title]")
    |> Test.Html.text()
  end
end
