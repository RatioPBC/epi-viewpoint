defmodule EpicenterWeb.MultiselectTest do
  use Epicenter.SimpleCase, async: true

  alias Epicenter.Test
  alias EpicenterWeb.Multiselect

  defmodule Movie do
    use Ecto.Schema

    @primary_key false

    embedded_schema do
      field :genres, :map
      field :languages, {:array, :string}
      field :status, :string
    end
  end

  defp phx_form(data) do
    %Movie{}
    |> Ecto.Changeset.change(Enum.into(data, %{}))
    |> Phoenix.HTML.Form.form_for("/url")
  end

  defp parse(safe),
    do: safe |> Phoenix.HTML.safe_to_string() |> Test.Html.parse()

  defp render(safe),
    do: safe |> parse() |> Test.Html.html()

  defp form_params(safe) do
    %Plug.Conn{resp_body: ~s|<form action="action">#{Phoenix.HTML.safe_to_string(safe)}</form>|}
    |> PhoenixIntegration.Requests.fetch_form()
    |> Map.get(:inputs)
  end

  describe "multiselect_inputs" do
    test "returns a list of multiselect inputs" do
      spec = [{:checkbox, "Comedy", "comedy"}, {:checkbox, "Scifi", "scifi"}]

      generated =
        phx_form(genres: %{"major" => %{"values" => ["comedy", "drama", "scifi"], "other" => "Something else"}})
        |> Multiselect.multiselect_inputs(:genres, spec)

      generated
      |> form_params()
      |> assert_eq(%{movie: %{genres: %{major: %{values: ["comedy", "scifi"]}}}})

      generated
      |> render()
      |> assert_html_eq("""
      <div class="label-wrapper">
        <label data-multiselect="parent" data-role="movie-genres">
          <input
            checked="checked"
            id="movie_genres_comedy"
            name="movie[genres][major][values][]"
            type="checkbox"
            value="comedy"/>\v
          Comedy\v
        </label>
      </div>
      <div class="label-wrapper">
        <label data-multiselect="parent" data-role="movie-genres">
          <input
            checked="checked"
            id="movie_genres_scifi"
            name="movie[genres][major][values][]"
            type="checkbox"
            value="scifi"/>\v
          Scifi\v
        </label>
      </div>
      """)
    end

    test "when field is a list, results in a set of form fields that phoenix parses as a list" do
      spec = [{:radio, "In Stock", "in-stock"}, {:radio, "Backordered", "backordered"}, {:radio, "Out of print", "oop"}]

      phx_form(status: "in-stock")
      |> Multiselect.multiselect_inputs(:status, spec, nil)
      |> form_params()
      |> assert_eq(%{movie: %{status: "in-stock"}})

      spec = [{:checkbox, "English", "english"}, {:checkbox, "French", "french"}, {:checkbox, "German", "german"}]

      phx_form(languages: ["english", "german"])
      |> Multiselect.multiselect_inputs(:languages, spec, nil)
      |> form_params()
      |> assert_eq(%{movie: %{languages: ["english", "german"]}})
    end

    test "when field is a map and spec has children, results in a set of form fields that phoenix parses as a map" do
      spec = [
        {:radio, "Unknown", "unknown"},
        {:checkbox, "Comedy", "comedy", [{:checkbox, "Dark Comedy", "dark-comedy"}, {:checkbox, "Musical Comedy", "musical-comedy"}]},
        {:checkbox, "Drama", "drama"},
        {:checkbox, "Scifi", "scifi", [{:checkbox, "Dystopian", "dystopian"}, {:checkbox, "Utoptian", "utopian"}, {:other_checkbox, "Other", nil}]},
        {:other_checkbox, "Other", nil}
      ]

      phx_form(
        genres: %{
          "major" => %{"values" => ["comedy", "drama", "scifi"], "other" => "Something else"},
          "detailed" => %{"comedy" => %{"values" => ["musical-comedy"]}, "scifi" => %{"values" => ["dystopian"], "other" => "Polytopian"}}
        }
      )
      |> Multiselect.multiselect_inputs(:genres, spec, nil)
      |> form_params()
      |> assert_eq(%{
        movie: %{
          genres: %{
            _ignore: %{major: %{other: "true"}, detailed: %{scifi: %{other: "true"}}},
            major: %{values: ["comedy", "drama", "scifi"], other: "Something else"},
            detailed: %{comedy: %{values: ["musical-comedy"]}, scifi: %{values: ["dystopian"], other: "Polytopian"}}
          }
        }
      })
    end
  end

  describe "multiselect_input" do
    test "given a string and a spec without children, returns a label and input" do
      spec = {:radio, "Status", "in-stock"}
      generated = phx_form(status: "in-stock") |> Multiselect.multiselect_input(:status, spec, :parent)

      assert form_params(generated) == %{movie: %{status: "in-stock"}}

      assert [{"div", [{"class", "label-wrapper"}], [{"label", label_attrs, [{"input", radio_attrs, []}, "Status"]}]}] = parse(generated)

      assert Enum.into(label_attrs, %{}) == %{
               "data-multiselect" => "parent",
               "data-role" => "movie-status"
             }

      assert Enum.into(radio_attrs, %{}) == %{
               "checked" => "checked",
               "id" => "movie_status_in_stock",
               "name" => "movie[status]",
               "type" => "radio",
               "value" => "in-stock"
             }
    end

    test "given a list and a spec without children, returns a label and input" do
      spec = {:checkbox, "English", "english"}
      generated = phx_form(languages: ["english", "french"]) |> Multiselect.multiselect_input(:languages, spec, :parent)

      assert form_params(generated) == %{movie: %{languages: ["english"]}}

      assert [{"div", [{"class", "label-wrapper"}], [{"label", label_attrs, [{"input", checkbox_attrs, []}, "English"]}]}] = parse(generated)

      assert Enum.into(label_attrs, %{}) == %{
               "data-multiselect" => "parent",
               "data-role" => "movie-languages"
             }

      assert Enum.into(checkbox_attrs, %{}) == %{
               "checked" => "checked",
               "id" => "movie_languages_english",
               "name" => "movie[languages][]",
               "type" => "checkbox",
               "value" => "english"
             }
    end

    test "given a map and a spec without children, returns a label and input" do
      spec = {:checkbox, "Comedy", "comedy"}

      generated =
        phx_form(genres: %{"major" => %{"values" => ["comedy", "drama", "scifi"], "other" => "Something else"}})
        |> Multiselect.multiselect_input(:genres, spec, :parent)

      assert form_params(generated) == %{movie: %{genres: %{major: %{values: ["comedy"]}}}}

      assert [{"div", [{"class", "label-wrapper"}], [{"label", label_attrs, [{"input", checkbox_attrs, []}, "Comedy"]}]}] = parse(generated)

      assert Enum.into(label_attrs, %{}) == %{
               "data-multiselect" => "parent",
               "data-role" => "movie-genres"
             }

      assert Enum.into(checkbox_attrs, %{}) == %{
               "checked" => "checked",
               "id" => "movie_genres_comedy",
               "name" => "movie[genres][major][values][]",
               "type" => "checkbox",
               "value" => "comedy"
             }
    end

    test "given a map and a spec with children, returns a label, input, and children" do
      spec =
        {:checkbox, "Comedy", "comedy",
         [
           {:checkbox, "Dark Comedy", "dark-comedy"},
           {:checkbox, "Musical Comedy", "musical-comedy"}
         ]}

      generated =
        phx_form(genres: %{"major" => %{"values" => ["comedy", "drama"]}, "detailed" => %{"comedy" => %{"values" => ["musical-comedy"]}}})
        |> Multiselect.multiselect_input(:genres, spec, nil)

      assert form_params(generated) == %{
               movie: %{
                 genres: %{
                   detailed: %{comedy: %{values: ["musical-comedy"]}},
                   major: %{values: ["comedy"]}
                 }
               }
             }

      assert [
               {"div", [{"class", "label-wrapper"}], [{"label", _, [{"input", comedy_attrs, []}, "Comedy"]}]},
               {"div", [{"class", "label-wrapper"}], [{"label", _, [{"input", dark_comedy_attrs, []}, "Dark Comedy"]}]},
               {"div", [{"class", "label-wrapper"}], [{"label", _, [{"input", musical_comedy_attrs, []}, "Musical Comedy"]}]}
             ] = parse(generated)

      assert Enum.into(comedy_attrs, %{}) == %{
               "checked" => "checked",
               "id" => "movie_genres_comedy",
               "name" => "movie[genres][major][values][]",
               "type" => "checkbox",
               "value" => "comedy"
             }

      assert Enum.into(dark_comedy_attrs, %{}) == %{
               "id" => "movie_genres_dark_comedy",
               "name" => "movie[genres][detailed][comedy][values][]",
               "type" => "checkbox",
               "value" => "dark-comedy"
             }

      assert Enum.into(musical_comedy_attrs, %{}) == %{
               "checked" => "checked",
               "id" => "movie_genres_musical_comedy",
               "name" => "movie[genres][detailed][comedy][values][]",
               "type" => "checkbox",
               "value" => "musical-comedy"
             }
    end

    test "when there is an 'other' field" do
      generated =
        phx_form(genres: %{"major" => %{"values" => ["comedy", "drama", "scifi"], "other" => "Something else"}})
        |> Multiselect.multiselect_input(:genres, {:other_radio, "Other", ""}, :parent)

      generated
      |> form_params()
      |> assert_eq(%{movie: %{genres: %{_ignore: %{major: %{other: "true"}}, major: %{other: "Something else"}}}})

      generated
      |> render()
      |> assert_html_eq("""
      <div class="label-wrapper">
        <label data-multiselect="parent" data-role="movie-genres">
          <input
            checked="checked"
            id="movie_genres_other"
            name="movie[genres][_ignore][major][other]"
            type="radio"
            value="true"/>\v
          Other\v
          <div data-multiselect="text-wrapper">
            <input
              data-role="other-text"
              id="movie_genres_other"
              name="movie[genres][major][other]"
              placeholder="Please specify"
              type="text"
              value="Something else"/>
          </div>
        </label>
      </div>
      """)
    end
  end

  describe "multiselect_chradio with :checkbox" do
    test "renders a checkbox" do
      generated =
        phx_form(genres: %{"major" => %{"values" => ["comedy", "drama", "scifi"], "other" => "Something else"}})
        |> Multiselect.multiselect_chradio(:genres, "comedy", :checkbox)

      assert form_params(generated) == %{movie: %{genres: %{major: %{values: ["comedy"]}}}}

      assert [{"input", attrs, []}] = parse(generated)

      assert attrs |> Enum.into(%{}) == %{
               "checked" => "checked",
               "id" => "movie_genres_comedy",
               "name" => "movie[genres][major][values][]",
               "type" => "checkbox",
               "value" => "comedy"
             }
    end
  end

  describe "multiselect_chradio with :radio" do
    test "renders a radio" do
      generated =
        phx_form(genres: %{"major" => %{"values" => ["comedy", "drama", "scifi"], "other" => "Something else"}})
        |> Multiselect.multiselect_chradio(:genres, "comedy", :radio)

      assert form_params(generated) == %{movie: %{genres: %{major: %{values: ["comedy"]}}}}

      assert [{"input", attrs, []}] = parse(generated)

      assert attrs |> Enum.into(%{}) == %{
               "checked" => "checked",
               "id" => "movie_genres_comedy",
               "name" => "movie[genres][major][values][]",
               "type" => "radio",
               "value" => "comedy"
             }
    end
  end

  describe "multiselect_other" do
    test "renders a chradio text field to be used for 'other'" do
      generated =
        phx_form(genres: %{"major" => %{"values" => ["comedy", "drama", "scifi"], "other" => "Something else"}})
        |> Multiselect.multiselect_other(:genres, "Other", :checkbox)

      generated
      |> form_params()
      |> assert_eq(%{movie: %{genres: %{major: %{other: "Something else"}, _ignore: %{major: %{other: "true"}}}}})

      generated
      |> render()
      |> assert_html_eq("""
      <input
        checked="checked"
        id="movie_genres_other"
        name="movie[genres][_ignore][major][other]"
        type="checkbox"
        value="true"/>\v
      Other\v
      <div data-multiselect="text-wrapper">
        <input
          data-role="other-text"
          id="movie_genres_other"
          name="movie[genres][major][other]"
          placeholder="Please specify"
          type="text"
          value="Something else"/>
      </div>
      """)
    end
  end

  describe "checked?" do
    test "with a value, a map, and a list of keys" do
      assert Multiselect.checked?("musical", %{"major" => %{"values" => ["comedy", "musical", "scifi"]}}, ["major", "values"])
      refute Multiselect.checked?("western", %{"major" => %{"values" => ["comedy", "musical", "scifi"]}}, ["major", "values"])
      refute Multiselect.checked?("western", %{"major" => %{}}, ["major", "values"])
      refute Multiselect.checked?("western", %{}, ["major", "values"])

      assert Multiselect.checked?("dystopian", %{"detailed" => %{"scifi" => %{"values" => ["dystopian"]}}}, ["detailed", "scifi", "values"])
      refute Multiselect.checked?("utopian", %{"detailed" => %{"scifi" => %{"values" => ["dystopian"]}}}, ["detailed", "scifi", "values"])
      refute Multiselect.checked?("utopian", %{"detailed" => %{}}, ["detailed", "scifi", "values"])
      refute Multiselect.checked?("utopian", %{}, ["detailed", "scifi", "values"])
    end

    test "with a value and a list" do
      assert Multiselect.checked?("musical", ["comedy", "musical", "scifi"])
      refute Multiselect.checked?("western", ["comedy", "musical", "scifi"])
      refute Multiselect.checked?(nil, ["comedy", "musical", "scifi"])
      refute Multiselect.checked?("western", [])
    end

    test "with a value and a scalar" do
      assert Multiselect.checked?("musical", "musical")
      refute Multiselect.checked?("musical", "comedy")
      refute Multiselect.checked?(nil, "comedy")
      refute Multiselect.checked?("musical", nil)
    end
  end
end
