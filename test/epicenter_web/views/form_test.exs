defmodule EpicenterWeb.FormTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Test
  alias EpicenterWeb.Form

  defmodule Movie do
    use Ecto.Schema

    @primary_key false

    embedded_schema do
      field :director, :string
      field :genres, {:array, :string}
      field :in_stock, :boolean
      field :language, :string
      field :producer, :string
      field :release_date, :date
      field :title, :string
    end
  end

  defp phx_form(data) do
    %Movie{}
    |> Ecto.Changeset.change(Enum.into(data, %{}))
    |> Phoenix.HTML.Form.form_for("/url")
  end

  # Convert a form into HTML and then parse into a list of 3-tuples, each of which is in the form:
  #   {html-element-name, [html-attrs ...], [children ...]}
  # which is the form that Floki generates and that Floki and Test.Html functions expect
  defp parse(%Form{} = form) do
    form
    |> Form.safe()
    |> Phoenix.HTML.safe_to_string()
    |> Test.Html.parse()
  end

  defp render(%Form{} = form) do
    form |> parse() |> render()
  end

  defp render(parsed_html) do
    parsed_html |> Test.Html.html()
  end

  test "creates a form with multiple fields" do
    parsed =
      phx_form(title: "Strange Brew", language: "English")
      |> Form.new()
      |> Form.line(&Form.text_field(&1, :title, "Title", 4))
      |> Form.line(&Form.text_field(&1, :language, "Language", 4))
      |> parse()

    assert [title_fieldset, language_fieldset] = parsed
    assert {"fieldset", [], [{"label", _, ["Title"]}, {"input", _, _}]} = title_fieldset
    assert {"fieldset", [], [{"label", _, ["Language"]}, {"input", _, _}]} = language_fieldset
  end

  test "multiple fields can be on the same line and their grid columns are automatically set" do
    parsed =
      phx_form(title: "Strange Brew", language: "English")
      |> Form.new()
      |> Form.line(fn line ->
        line
        |> Form.text_field(:title, "Title", 2)
        |> Form.text_field(:language, "Language", 2)
      end)
      |> parse()

    assert [mutli_line_fieldset] = parsed
    assert {"fieldset", [], [title_label, title_input, language_label, language_input]} = mutli_line_fieldset
    assert {"label", _, ["Title"]} = title_label
    assert {"input", _, _} = title_input
    assert {"label", _, ["Language"]} = language_label
    assert {"input", _, _} = language_input

    assert Test.Html.attr(title_label, "data-grid-col") == ["1"]
    assert Test.Html.attr(title_input, "data-grid-col") == ["1"]
    assert Test.Html.attr(language_label, "data-grid-col") == ["3"]
    assert Test.Html.attr(language_input, "data-grid-col") == ["3"]
  end

  test "select" do
    parsed =
      phx_form(language: "English")
      |> Form.new()
      |> Form.line(&Form.select(&1, :language, "Language", [{"Italian", "italian"}, {"English", "english"}], 4))
      |> parse()

    assert [{"fieldset", [], [label, select_wrapper]}] = parsed
    assert {"div", _, [{"svg", _, _}, select]} = select_wrapper

    label
    |> render()
    |> assert_html_eq("""
    <label
      data-grid-col="1"
      data-grid-row="1"
      data-grid-span="4"
      for="movie_language">Language</label>
    """)

    select
    |> render()
    |> assert_html_eq("""
    <select
      data-grid-col="1"
      data-grid-row="3"
      data-grid-span="4"
      id="movie_language"
      name="movie[language]">\v
      <option value="italian">Italian</option>\v
      <option value="english">English</option>\v
    </select>
    """)
  end

  test "text_field" do
    phx_form(title: "Strange Brew")
    |> Form.new()
    |> Form.line(&Form.text_field(&1, :title, "Title", 3))
    |> render()
    |> assert_html_eq("""
    <fieldset>
      <label
        data-grid-col="1"
        data-grid-row="1"
        data-grid-span="3"
        for="movie_title">Title</label>
      <input
        data-grid-col="1"
        data-grid-row="3"
        data-grid-span="3"
        id="movie_title"
        name="movie[title]"
        type="text"
        value="Strange Brew"/>
    </fieldset>
    """)
  end
end
