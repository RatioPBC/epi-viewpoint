defmodule EpicenterWeb.StyleguideLiveTest do
  use EpicenterWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Epicenter.Extra
  alias Epicenter.Test
  alias EpicenterWeb.Test.Pages
  alias Phoenix.LiveViewTest.View

  describe "renders without error" do
    test "main styleguide page", %{conn: conn} do
      conn |> Pages.visit("/styleguide") |> render()
    end

    test "form-builder styleguide page", %{conn: conn} do
      conn |> Pages.visit("/styleguide/form-builder") |> render()
    end

    test "form-multiselect styleguide page", %{conn: conn} do
      conn |> Pages.visit("/styleguide/form-multiselect") |> render()
    end

    test "investigation notes styleguide page", %{conn: conn} do
      conn |> Pages.visit("/styleguide/investigation-notes-section") |> render()
    end
  end

  describe "multiselect" do
    setup %{conn: conn} do
      [view: conn |> Pages.visit("/styleguide/form-multiselect")]
    end

    defp check(%View{} = view, keypath, value) do
      target = [:example_form | keypath] |> Enum.map(&to_string/1)
      map = Extra.Map.put_in(%{}, keypath, value, on_conflict: :replace)
      view |> element("form") |> render_change(%{_target: target, example_form: map})
    end

    defp checked(%View{} = view, name) do
      labels =
        view
        |> render()
        |> Test.Html.parse()
        |> Test.Html.find("div[data-role=multiselect-example-form-#{name}] label")

      checked =
        labels
        |> Enum.filter(&(Test.Html.find(&1, "input[checked=checked]") != []))
        |> Enum.map(&Test.Html.text/1)

      other =
        Test.Html.find(labels, "[data-role=other-text]")
        |> Enum.map(&Test.Html.attr(&1, "value"))
        |> List.flatten()
        |> List.first()

      if other,
        do: %{checked: checked, other: other},
        else: %{checked: checked}
    end

    test "radios", %{view: view} do
      assert_that check(view, ~w{radios}a, "r4"),
        changes: checked(view, "radios"),
        from: %{checked: ["R2"]},
        to: %{checked: ["R4"]}
    end

    test "radios with other", %{view: view} do
      assert_that check(view, ~w{radios_with_other _ignore major other}a, true),
        changes: checked(view, "radios-with-other"),
        from: %{checked: ["R2"], other: ""},
        to: %{checked: ["Other"], other: ""}
    end

    test "radios with other preselected", %{view: view} do
      assert_that check(view, ~w{radios_with_other_preselected major values }a, ["r2"]),
        changes: checked(view, "radios-with-other-preselected"),
        from: %{checked: ["Other"], other: "r4"},
        to: %{checked: ["R2"], other: ""}
    end

    test "checkboxes", %{view: view} do
      assert_that check(view, ~w{checkboxes}a, ["c1", "c2", "c3"]),
        changes: checked(view, "checkboxes"),
        from: %{checked: ["C1", "C3"]},
        to: %{checked: ["C1", "C2", "C3"]}
    end

    test "mixed", %{view: view} do
      assert_that check(view, ~w{radios_and_checkboxes}a, ["r1", "c1", "c2"]),
        changes: checked(view, "radios-and-checkboxes"),
        from: %{checked: ["C1"]},
        to: %{checked: ["R1", "C1", "C2"]}
    end

    test "with other (mixed)", %{view: view} do
      assert_that check(view, ~w{radios_and_checkboxes_with_other _ignore major other}a, true),
        changes: checked(view, "radios-and-checkboxes-with-other"),
        from: %{checked: ["C1"], other: ""},
        to: %{checked: ["C1", "Other"], other: ""}
    end

    test "radios + nested checkboxes", %{view: view} do
      assert_that check(view, ~w{radios_with_nested_checkboxes detailed r3 values}a, ["c3"]),
        changes: checked(view, "radios-with-nested-checkboxes"),
        from: %{checked: ["R2"]},
        to: %{checked: ["R3", "C3"]}
    end

    test "mixed + nested checkboxes", %{view: view} do
      assert_that check(view, ~w{radios_and_checkboxes_with_nested_checkboxes detailed c2 values}a, ["c2.1"]),
        changes: checked(view, "radios-and-checkboxes-with-nested-checkboxes"),
        from: %{checked: ["C1", "C1.1", "C1.3", "C2"]},
        to: %{checked: ["C1", "C1.1", "C1.3", "C2", "C2.1"]}
    end
  end
end
