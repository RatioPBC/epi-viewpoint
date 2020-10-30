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

  @languages [{"Italian", "italian"}, {"English", "english"}]
  @genres ~w{Comedy Drama Musical}

  defp phx_form(data \\ %{}) do
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
      |> Form.line(&Form.text_field(&1, :title, "Title", span: 4))
      |> Form.line(&Form.text_field(&1, :language, "Language", span: 4))
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
        |> Form.text_field(:title, "Title", span: 2)
        |> Form.text_field(:language, "Language", span: 2)
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

  test "checkbox_list" do
    phx_form(genres: ~w{Comedy Musical})
    |> Form.new()
    |> Form.line(&Form.checkbox_list(&1, :genres, "Genres", @genres, span: 3))
    |> render()
    |> assert_html_eq("""
    <fieldset>
      <label data-grid-col="1" data-grid-row="1" data-grid-span="3" for="movie_genres">Genres</label>
      <div class="checkbox-list" data-grid-col="1" data-grid-row="3" data-grid-span="3">
        <label data-role="movie-genres">\v
          <input id="movie_genres" name="movie[genres][]" type="checkbox" value="Comedy" checked="checked"/>Comedy\v
        </label>
        <label data-role="movie-genres">\v
          <input id="movie_genres" name="movie[genres][]" type="checkbox" value="Drama"/>Drama\v
        </label>
        <label data-role="movie-genres">\v
          <input id="movie_genres" name="movie[genres][]" type="checkbox" value="Musical" checked="checked"/>Musical\v
        </label>
      </div>
    </fieldset>
    """)
  end

  test "content_div" do
    phx_form()
    |> Form.new()
    |> Form.line(&Form.content_div(&1, "some content"))
    |> render()
    |> assert_html_eq("""
    <fieldset>
      <div data-grid-col="1" data-grid-row="1" data-grid-span="2">some content</div>
    </fieldset>
    """)
  end

  test "date_field" do
    phx_form(release_date: ~D[2000-01-02])
    |> Form.new()
    |> Form.line(&Form.date_field(&1, :release_date, "Release date", span: 4))
    |> render()
    |> assert_html_eq("""
    <fieldset>
      <label data-grid-col="1" data-grid-row="1" data-grid-span="4" for="movie_release_date">Release date</label>
      <div data-grid-col="1" data-grid-row="2" data-grid-span="4">MM/DD/YYYY</div>
      <input
        data-grid-col="1"
        data-grid-row="4"
        data-grid-span="4"
        id="movie_release_date"
        name="movie[release_date]"
        type="text"
        value="2000-01-02"/>
    </fieldset>
    """)
  end

  test "footer" do
    phx_form(language: "English")
    |> Form.new()
    |> Form.line(&Form.footer(&1, "some error message"))
    |> render()
    |> assert_html_eq("""
    <fieldset>
      <footer>
        <button type="submit">Save</button>
        <div class="form-error-message" data-form-error-message="some error message">some error message</div>
      </footer>
    </fieldset>
    """)
  end

  test "radio_button_list" do
    phx_form(language: "English")
    |> Form.new()
    |> Form.line(&Form.radio_button_list(&1, :language, "Language", @languages, other: "Other", span: 5))
    |> render()
    |> assert_html_eq("""
    <fieldset>
      <label data-grid-col="1" data-grid-row="1" data-grid-span="5" for="movie_language">\v
        Language\v
      </label>
      <div class="radio-button-list" data-grid-col="1" data-grid-row="3" data-grid-span="5">
        <label data-role="movie-language">
          <input id="movie_language_" name="movie[language]" type="radio" value="" checked="checked"/>\v
          Other\v

          <input data-reveal="when-parent-checked" id="movie_language" name="movie[language]" type="text" value="English"/>
        </label>
        <label data-role="movie-language">
          <input id="movie_language_english" name="movie[language]" type="radio" value="english"/>\v
          English\v
        </label>
        <label data-role="movie-language">
          <input id="movie_language_italian" name="movie[language]" type="radio" value="italian"/>\v
          Italian\v
        </label>
      </div>
    </fieldset>
    """)
  end

  test "save_button" do
    phx_form()
    |> Form.new()
    |> Form.line(&Form.save_button(&1))
    |> render()
    |> assert_html_eq("""
    <fieldset>\v
      <button data-grid-col="1" data-grid-row="1" data-grid-span="2" type="submit">Save</button>\v
    </fieldset>
    """)
  end

  test "select" do
    parsed =
      phx_form(language: "English")
      |> Form.new()
      |> Form.line(&Form.select(&1, :language, "Language", @languages, span: 4))
      |> parse()

    assert [{"fieldset", [], [label, select_wrapper]}] = parsed
    assert {"div", _, [{"svg", _, _}, select]} = select_wrapper

    label
    |> render()
    |> assert_html_eq("""
    <label data-grid-col="1" data-grid-row="1" data-grid-span="4" for="movie_language">\v
      Language\v
    </label>
    """)

    select
    |> render()
    |> assert_html_eq("""
    <select data-grid-col="1" data-grid-row="3" data-grid-span="4" id="movie_language" name="movie[language]">\v
      <option value="italian">Italian</option>\v
      <option value="english">English</option>\v
    </select>
    """)
  end

  test "text_field" do
    phx_form(title: "Strange Brew")
    |> Form.new()
    |> Form.line(&Form.text_field(&1, :title, "Title", span: 3))
    |> render()
    |> assert_html_eq("""
    <fieldset>
      <label data-grid-col="1" data-grid-row="1" data-grid-span="3" for="movie_title">\v
        Title\v
      </label>
      <input
        data-grid-col="1" data-grid-row="3" data-grid-span="3"
        id="movie_title" name="movie[title]" type="text" value="Strange Brew"
      />
    </fieldset>
    """)
  end
end
