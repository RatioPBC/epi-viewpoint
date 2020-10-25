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
      |> Phoenix.HTML.safe_to_string()
      |> assert_eq(~s|<input id="movie_genres" name="movie[genres][]" type="checkbox" value="Comedy">|)
    end

    test "marks the checkbox as checked if it's in the form data", %{form: form} do
      FormHelpers.checkbox_list_checkbox(form, :genres, "Drama")
      |> Phoenix.HTML.safe_to_string()
      |> assert_eq(~s|<input id="movie_genres" name="movie[genres][]" type="checkbox" value="Drama" checked>|)
    end
  end

  describe "checkbox_list" do
    test "returns a rendered checkbox list", %{form: form} do
      FormHelpers.checkbox_list(form, :genres, ["Comedy", "Drama", "Musical", "Science Fiction"], id: "genre-list")
      |> Phoenix.HTML.safe_to_string()
      |> assert_eq(
        """
        <div class="checkbox-list" id="genre-list">
        <label><input id="movie_genres" name="movie[genres][]" type="checkbox" value="Comedy"> Comedy</label>
        <label><input id="movie_genres" name="movie[genres][]" type="checkbox" value="Drama" checked> Drama</label>
        <label><input id="movie_genres" name="movie[genres][]" type="checkbox" value="Musical"> Musical</label>
        <label><input id="movie_genres" name="movie[genres][]" type="checkbox" value="Science Fiction"> Science Fiction</label>
        </div>
        """
        |> String.replace("\n", "")
      )
    end
  end

  describe "radio_button_list" do
    test "returns a rendered radio button list", %{form: form} do
      FormHelpers.radio_button_list(form, :language, ["English", "German", "Italian"], id: "language-list")
      |> Phoenix.HTML.safe_to_string()
      |> assert_eq(
        """
        <div class="radio-button-list" id="language-list">
        <label><input id="movie_language_English" name="movie[language]" type="radio" value="English"> English</label>
        <label><input id="movie_language_German" name="movie[language]" type="radio" value="German" checked> German</label>
        <label><input id="movie_language_Italian" name="movie[language]" type="radio" value="Italian"> Italian</label>
        </div>
        """
        |> String.replace("\n", "")
      )
    end
  end
end
