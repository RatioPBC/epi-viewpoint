defmodule EpicenterWeb.MultiselectTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Test
  alias EpicenterWeb.Multiselect

  defmodule Movie do
    use Ecto.Schema

    @primary_key false

    embedded_schema do
      field :genres, {:array, :string}
    end
  end

  defp phx_form(data) do
    %Movie{}
    |> Ecto.Changeset.change(Enum.into(data, %{}))
    |> Phoenix.HTML.Form.form_for("/url")
  end

  defp parse(safe) do
    safe
    |> Phoenix.HTML.safe_to_string()
    |> Test.Html.parse()
  end

  defp render(safe) do
    safe |> Phoenix.HTML.safe_to_string() |> Test.Html.parse() |> Test.Html.html()
  end

  describe "multiselect_inputs" do
    test "returns a list of multiselect inputs" do
      phx_form(genres: ["comedy", "musical"])
      |> Multiselect.multiselect_inputs(:genres, [{:checkbox, "Comedy", "comedy"}, {:checkbox, "Musical", "musical"}])
      |> render()
      |> assert_html_eq("""
      <div class="label-wrapper">
        <label data-multiselect="parent" data-role="movie-genres">
          <input
            data-multiselect-parent-id=""
            id="movie_genres_comedy"
            name="movie[genres][]"
            phx-hook="Multiselect"
            type="checkbox"
            value="comedy"
            checked="checked"/>\v
          Comedy\v
        </label>
      </div>
      <div class="label-wrapper">
        <label data-multiselect="parent" data-role="movie-genres">
          <input
          data-multiselect-parent-id=""
          id="movie_genres_musical"
          name="movie[genres][]"
          phx-hook="Multiselect"
          type="checkbox"
          value="musical"
          checked="checked"/>\v
          Musical\v
        </label>
      </div>
      """)
    end
  end

  describe "multiselect_input" do
    test "when there are no children, returns a label and input" do
      assert [{"div", [{"class", "label-wrapper"}], [{"label", label_attrs, [{"input", checkbox_attrs, []}, "Comedy"]}]}] =
               phx_form(genres: ["comedy", "musical"])
               |> Multiselect.multiselect_input(:genres, {:checkbox, "Comedy", "comedy"}, nil)
               |> parse()

      assert Enum.into(label_attrs, %{}) == %{
               "data-multiselect" => "parent",
               "data-role" => "movie-genres"
             }

      assert Enum.into(checkbox_attrs, %{}) == %{
               "checked" => "checked",
               "data-multiselect-parent-id" => "",
               "id" => "movie_genres_comedy",
               "name" => "movie[genres][]",
               "phx-hook" => "Multiselect",
               "type" => "checkbox",
               "value" => "comedy"
             }
    end

    test "when there are children, returns a label, input, and children" do
      comedy_sub_values = [{:checkbox, "Dark Comedy", "dark-comedy"}, {:checkbox, "Musical Comedy", "musical-comedy"}]
      value = {:checkbox, "Comedy", "comedy", comedy_sub_values}

      assert [
               {"div", [{"class", "label-wrapper"}], [{"label", _, [{"input", comedy_attrs, []}, "Comedy"]}]},
               {"div", [{"class", "label-wrapper"}], [{"label", _, [{"input", dark_comedy_attrs, []}, "Dark Comedy"]}]},
               {"div", [{"class", "label-wrapper"}], [{"label", _, [{"input", musical_comedy_attrs, []}, "Musical Comedy"]}]}
             ] =
               phx_form(genres: ["comedy", "musical"])
               |> Multiselect.multiselect_input(:genres, value, nil)
               |> parse()

      assert Enum.into(comedy_attrs, %{}) == %{
               "checked" => "checked",
               "data-multiselect-parent-id" => "",
               "id" => "movie_genres_comedy",
               "name" => "movie[genres][]",
               "phx-hook" => "Multiselect",
               "type" => "checkbox",
               "value" => "comedy"
             }

      assert Enum.into(dark_comedy_attrs, %{}) == %{
               "data-multiselect-parent-id" => "movie_genres_comedy",
               "id" => "movie_genres_comedy_dark_comedy",
               "name" => "movie[genres_comedy][]",
               "phx-hook" => "Multiselect",
               "type" => "checkbox",
               "value" => "dark-comedy"
             }

      assert Enum.into(musical_comedy_attrs, %{}) == %{
               "data-multiselect-parent-id" => "movie_genres_comedy",
               "id" => "movie_genres_comedy_musical_comedy",
               "name" => "movie[genres_comedy][]",
               "phx-hook" => "Multiselect",
               "type" => "checkbox",
               "value" => "musical-comedy"
             }
    end

    test "when there is an 'other' field" do
      assert [
               {"div", [{"class", "label-wrapper"}],
                [
                  {
                    "label",
                    [{"data-multiselect", "parent"}, {"data-role", "movie-genres"}],
                    [{"input", radio_attrs, []}, "Comedy", {"div", [{"data-multiselect", "text-wrapper"}], [{"input", text_field_attrs, []}]}]
                  }
                ]}
             ] =
               phx_form(genres: ["comedy", "musical"])
               |> Multiselect.multiselect_input(:genres, {:other_radio, "Comedy", "comedy"}, nil)
               |> parse()

      assert Enum.into(radio_attrs, %{}) == %{
               "checked" => "checked",
               "data-multiselect-parent-id" => "",
               "id" => "movie_genres_comedy",
               "name" => "movie[genres]_other",
               "phx-hook" => "Multiselect",
               "type" => "radio",
               "value" => "comedy"
             }

      assert Enum.into(text_field_attrs, %{}) == %{
               "data-multiselect-parent-id" => "movie_genres_comedy",
               "id" => "movie_genres",
               "name" => "movie[genres][]",
               "type" => "text",
               "value" => "comedy"
             }
    end
  end

  describe "multiselect_checkbox" do
    test "renders a checkbox" do
      assert [{"input", attrs, []}] =
               phx_form(genres: ["comedy", "musical"])
               |> Multiselect.multiselect_checkbox(:genres, "comedy", "parent-id")
               |> parse()

      assert attrs |> Enum.into(%{}) == %{
               "checked" => "checked",
               "data-multiselect-parent-id" => "parent-id",
               "id" => "movie_genres_comedy",
               "name" => "movie[genres][]",
               "phx-hook" => "Multiselect",
               "type" => "checkbox",
               "value" => "comedy"
             }
    end
  end

  describe "multiselect_radio" do
    test "renders a radio" do
      assert [{"input", attrs, []}] =
               phx_form(genres: ["comedy", "musical"])
               |> Multiselect.multiselect_radio(:genres, "comedy", "parent-id")
               |> parse()

      assert attrs |> Enum.into(%{}) == %{
               "checked" => "checked",
               "data-multiselect-parent-id" => "parent-id",
               "id" => "movie_genres_comedy",
               "name" => "movie[genres][]",
               "phx-hook" => "Multiselect",
               "type" => "radio",
               "value" => "comedy"
             }
    end
  end

  describe "multiselect_text" do
    test "renders a text field to be used for 'other'" do
      assert [{"div", [{"data-multiselect", "text-wrapper"}], [{"input", attrs, []}]}] =
               phx_form(genres: ["comedy", "musical"])
               |> Multiselect.multiselect_text(:genres, "comedy")
               |> parse()

      assert attrs |> Enum.into(%{}) == %{
               "data-multiselect-parent-id" => "movie_genres_comedy",
               "id" => "movie_genres",
               "name" => "movie[genres][]",
               "type" => "text",
               "value" => "comedy"
             }
    end
  end
end
