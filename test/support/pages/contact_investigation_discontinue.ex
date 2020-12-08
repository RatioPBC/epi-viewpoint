defmodule EpicenterWeb.Test.Pages.ContactInvestigationDiscontinue do
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  import Phoenix.LiveViewTest

  def visit(conn, exposure) do
    conn |> Pages.visit("/contact-investigations/#{exposure.id}/discontinue")
  end

  def assert_here(%View{} = view, exposure) do
    view
    |> render()
    |> Pages.parse()
    |> Test.Html.find!("[data-role=contact-investigation-discontinue-page][data-exposure-id=#{exposure.id}]")

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
