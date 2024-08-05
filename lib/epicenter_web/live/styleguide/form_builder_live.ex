defmodule EpicenterWeb.Styleguide.FormBuilderLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers,
    only: [assign_defaults: 1, assign_page_title: 2, noreply: 1, ok: 1]

  alias EpicenterWeb.Form

  defmodule MovieForm do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false

    embedded_schema do
      field(:director, :string)
      field(:genres, {:array, :string})
      field(:language, :string)
      field(:notes, :string)
      field(:producer, :string)
      field(:release_date, :string)
      field(:status, :string)
      field(:title, :string)
    end

    @required_attrs ~w{director language release_date title}a
    @optional_attrs ~w{genres producer status}a

    def changeset(form_attrs) do
      %MovieForm{}
      |> cast(form_attrs, @required_attrs ++ @optional_attrs)
      |> validate_required(@required_attrs)
    end
  end

  def mount(_params, _session, socket) do
    socket
    |> assign_defaults()
    |> assign_page_title("Styleguide: form builder")
    |> assign(show_nav: false)
    |> assign(
      form_changeset:
        MovieForm.changeset(%{
          director: nil,
          genres: ["Comedy", "Drama"],
          in_stock: false,
          language: "Spanish",
          producer: "Louis M. Silverstein",
          release_date: nil,
          title: "Strange Brew"
        })
    )
    |> assign(movie: nil)
    |> ok()
  end

  def handle_event("save", %{"movie_form" => params}, socket) do
    {_, changeset} = MovieForm.changeset(params)
    socket |> assign(form_changeset: changeset) |> noreply()
  end

  # # #

  def genres(),
    do: [
      {"Comedy", "comedy"},
      {"Drama", "drama"},
      {"Musical", "musical"},
      {"Science Fiction", "scifi"}
    ]

  def languages(),
    do: [{"English", "english"}, {"German", "german"}, {"Italian", "italian"}]

  def statuses(),
    do: [{"In Stock", "in-stock"}, {"Out Of Stock", "out-of-stock"}]

  # # #

  def movie_form_builder(form) do
    Form.new(form)
    |> Form.line(&Form.text_field(&1, :title, "Title", span: 4))
    |> Form.line(fn line ->
      line
      |> Form.text_field(:director, "Director")
      |> Form.text_field(:producer, "Producer")
    end)
    |> Form.line(fn line ->
      line
      |> Form.checkbox_list(:genres, "Genres", genres(), other: "Other genres")
      |> Form.radio_button_list(:language, "Language", languages(), other: "Other")
    end)
    |> Form.line(&Form.textarea_field(&1, :notes, "Notes", span: 4))
    |> Form.safe()
  end
end
