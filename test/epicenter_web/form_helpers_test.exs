defmodule EpicenterWeb.FormHelpersTest do
  use Epicenter.SimpleCase, async: true

  alias Ecto.Changeset
  alias EpicenterWeb.FormHelpers

  defmodule Movie do
    use Ecto.Schema

    schema "movie" do
      field :genres, {:array, :string}
      field :language, :string
    end
  end

  setup do
    changeset = Changeset.change(%Movie{genres: ["Drama"], language: "German"})
    form = Phoenix.HTML.FormData.to_form(changeset, [])
    [form: form]
  end

  describe "checkbox_list_input_name" do
    test "returns a form input name that's appropriate for a checkbox in a checkbox list", %{form: form} do
      assert FormHelpers.checkbox_list_input_name(form, :genres) == "movie[genres][]"
    end
  end

  describe "checkbox_list_checkbox" do
    test "returns a checkbox that's meant to be part of a checkbox list", %{form: form} do
      FormHelpers.checkbox_list_checkbox(form, :genres, "Comedy")
      |> assert_html_eq(~s|<input id="movie_genres" name="movie[genres][]" type="checkbox" value="Comedy">|)
    end

    test "marks the checkbox as checked if it's in the form data", %{form: form} do
      FormHelpers.checkbox_list_checkbox(form, :genres, "Drama")
      |> assert_html_eq(~s|<input id="movie_genres" name="movie[genres][]" type="checkbox" value="Drama" checked/>|)
    end
  end

  describe "checkbox_list" do
    test "returns a rendered checkbox list", %{form: form} do
      FormHelpers.checkbox_list(form, :genres, ["Comedy", "Drama", "Musical", "Science Fiction"], id: "genre-list")
      |> assert_html_eq("""
      <div class="checkbox-list" id="genre-list">
        <label data-role="movie-genres"><input id="movie_genres" name="movie[genres][]" type="checkbox" value="Comedy"/>Comedy</label>
        <label data-role="movie-genres"><input id="movie_genres" name="movie[genres][]" type="checkbox" value="Drama" checked/>Drama</label>
        <label data-role="movie-genres"><input id="movie_genres" name="movie[genres][]" type="checkbox" value="Musical"/>Musical</label>
        <label data-role="movie-genres"><input id="movie_genres" name="movie[genres][]" type="checkbox" value="Science Fiction"/>Science Fiction</label>
      </div>
      """)
    end

    test "renders a checkbox list with differing label text and input values" do
      changeset = Changeset.change(%Movie{genres: ["drama"]})
      form = Phoenix.HTML.FormData.to_form(changeset, [])

      FormHelpers.checkbox_list(form, :genres, [{"Comedy", "comedy"}, {"Drama", "drama"}, {"Musical", "musical"}, {"Science Fiction", "sci_fi"}],
        id: "genre-list"
      )
      |> assert_html_eq("""
      <div class="checkbox-list" id="genre-list">
        <label data-role="movie-genres"><input id="movie_genres" name="movie[genres][]" type="checkbox" value="comedy"/>Comedy</label>
        <label data-role="movie-genres"><input id="movie_genres" name="movie[genres][]" type="checkbox" value="drama" checked/>Drama</label>
        <label data-role="movie-genres"><input id="movie_genres" name="movie[genres][]" type="checkbox" value="musical"/>Musical</label>
        <label data-role="movie-genres"><input id="movie_genres" name="movie[genres][]" type="checkbox" value="sci_fi"/>Science Fiction</label>
      </div>
      """)
    end

    test "renders a checkbox list without a value present in the changeset" do
      changeset = Changeset.change(%Movie{genres: nil})
      form = Phoenix.HTML.FormData.to_form(changeset, [])

      FormHelpers.checkbox_list(form, :genres, ["Comedy", "Drama", "Musical", "Science Fiction"], id: "genre-list")
      |> assert_html_eq("""
      <div class="checkbox-list" id="genre-list">
        <label data-role="movie-genres"><input id="movie_genres" name="movie[genres][]" type="checkbox" value="Comedy"/>Comedy</label>
        <label data-role="movie-genres"><input id="movie_genres" name="movie[genres][]" type="checkbox" value="Drama"/>Drama</label>
        <label data-role="movie-genres"><input id="movie_genres" name="movie[genres][]" type="checkbox" value="Musical"/>Musical</label>
        <label data-role="movie-genres"><input id="movie_genres" name="movie[genres][]" type="checkbox" value="Science Fiction"/>Science Fiction</label>
      </div>
      """)
    end
  end

  describe "radio_button_list" do
    test "renders radio buttons in reverse order, which get un-reversed via css", %{form: form} do
      FormHelpers.radio_button_list(form, :language, ["English", "German", "Italian"], id: "language-list")
      |> assert_html_eq("""
      <div class="radio-button-list" id="language-list">
        <label data-role="movie-language"><input id="movie_language_Italian" name="movie[language]" type="radio" value="Italian"/>Italian</label>
        <label data-role="movie-language"><input id="movie_language_German" name="movie[language]" type="radio" value="German" checked="checked"/>German</label>
        <label data-role="movie-language"><input id="movie_language_English" name="movie[language]" type="radio" value="English"/>English</label>
      </div>
      """)
    end

    test "optionally includes an 'other' option with an associated text input", %{form: form} do
      FormHelpers.radio_button_list(form, :language, ["English", "Italian"], [other: "Other"], id: "language-list")
      |> assert_html_eq("""
      <div class="radio-button-list" id="language-list">
        <label data-role="movie-language"><input id="movie_language_" name="movie[language]" type="radio" value="" checked="checked"/>Other<input data-reveal="when-parent-checked" id="movie_language" name="movie[language]" type="text" value="German"></label>
        <label data-role="movie-language"><input id="movie_language_Italian" name="movie[language]" type="radio" value="Italian"/>Italian</label>
        <label data-role="movie-language"><input id="movie_language_English" name="movie[language]" type="radio" value="English"/>English</label>
      </div>
      """)
    end

    test "renders radio buttons with differing label text and input values" do
      changeset = Changeset.change(%Movie{language: "deutsch"})
      form = Phoenix.HTML.FormData.to_form(changeset, [])

      FormHelpers.radio_button_list(form, :language, [{"English", "english"}, {"German", "deutsch"}, {"Italian", "italiano"}], id: "language-list")
      |> assert_html_eq("""
      <div class="radio-button-list" id="language-list">
        <label data-role="movie-language"><input id="movie_language_italiano" name="movie[language]" type="radio" value="italiano"/>Italian</label>
        <label data-role="movie-language"><input id="movie_language_deutsch" name="movie[language]" type="radio" value="deutsch" checked="checked"/>German</label>
        <label data-role="movie-language"><input id="movie_language_english" name="movie[language]" type="radio" value="english"/>English</label>
      </div>
      """)
    end
  end

  describe "select_with_wrapper" do
    test "renders a select inside a div with 'select-wrapper' class and an icon", %{form: form} do
      options = [{"English", "English"}, {"Deutsche", "German"}, {"Español", "Spanish"}]

      FormHelpers.select_with_wrapper(form, :language, options, data: [grid: [row: 3, col: 1, span: 2]])
      |> assert_html_eq("""
      <div class="select-wrapper" data-grid-col="1" data-grid-row="3" data-grid-span="2">
        <svg width="20" height="20" viewbox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M7.41 8.59003L12 13.17L16.59 8.59003L18 10L12 16L6 10L7.41 8.59003Z" fill="black" fill-opacity="0.87"></path>
        </svg>
        <select data-grid-col="1" data-grid-row="3" data-grid-span="2" id="movie_language" name="movie[language]">
          <option value="English">English</option>
          <option value="German" selected>Deutsche</option>
          <option value="Spanish">Español</option>
        </select>
      </div>
      """)
    end
  end
end
