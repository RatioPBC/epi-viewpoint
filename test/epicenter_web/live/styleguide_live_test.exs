defmodule EpicenterWeb.StyleguideLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias EpicenterWeb.Test.Pages

  describe "renders without error" do
    test "main styleguide page", %{conn: conn} do
      conn |> Pages.visit("/styleguide") |> render()
    end

    test "form styleguide page", %{conn: conn} do
      conn |> Pages.visit("/styleguide/form") |> render()
    end

    test "form-builder styleguide page", %{conn: conn} do
      conn |> Pages.visit("/styleguide/form-builder") |> render()
    end

    @tag :skip
    test "form-multiselect styleguide page", %{conn: conn} do
      conn |> Pages.visit("/styleguide/form-multiselect") |> render()
    end

    test "investigation notes styleguide page", %{conn: conn} do
      conn |> Pages.visit("/styleguide/investigation-notes-section") |> render()
    end
  end
end
