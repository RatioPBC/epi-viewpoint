defmodule EpicenterWeb.Styleguide.FormBuilderLive do
  use EpicenterWeb, :live_view

  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, noreply: 1, ok: 1]

  defmodule MovieForm do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false

    embedded_schema do
      field :director, :string
      field :genres, {:array, :string}
      field :language, :string
      field :producer, :string
      field :release_date, :string
      field :status, :string
      field :title, :string
    end

    @required_attrs ~w{director language release_date title}a
    @optional_attrs ~w{genres producer status}a

    def changeset(form_attrs) do
      %MovieForm{}
      |> cast(form_attrs, @required_attrs ++ @optional_attrs)
      |> validate_required(@required_attrs)
    end
  end

  # form builder
  defmodule Form do
    use Phoenix.HTML

    defstruct ~w{f safe}a

    defmodule Line do
      defstruct ~w{column f safe}a
    end

    def new(f),
      do: %Form{f: f, safe: []}

    def safe(%Form{safe: safe}),
      do: {:safe, safe}

    def line(%Form{} = form, fun) do
      line = %Line{column: 1, f: form.f, safe: []} |> fun.()
      %{form | safe: merge_safe(form.safe, content_tag(:fieldset, line.safe))}
    end

    # # #

    def checkbox_list_field(%Form.Line{f: f} = line, field, name, values, span \\ 2) do
      [
        label(f, field, name, data: grid_data(1, line, span)),
        error_tag(f, field, data: grid_data(2, line, span)),
        checkbox_list(f, field, values, data: grid_data(3, line, span))
      ]
      |> add_to_line(line, span)
    end

    def text_field(%Form.Line{f: f} = line, field, name, span \\ 2) do
      [
        label(f, field, name, data: grid_data(1, line, span)),
        error_tag(f, field, data: grid_data(2, line, span)),
        text_input(f, field, data: grid_data(3, line, span))
      ]
      |> add_to_line(line, span)
    end

    # # #

    defp grid_data(row, %Form.Line{column: column}, span),
      do: [grid: [row: row, col: column, span: span]]

    defp add_to_line(contents, %Form.Line{column: column, safe: safe} = line, span),
      do: %{line | column: column + span, safe: safe ++ contents}

    defp merge_safe({:safe, left}, {:safe, right}), do: left ++ right
    defp merge_safe(left, {:safe, right}), do: left ++ right
    defp merge_safe({:safe, left}, right), do: left ++ right
  end

  def mount(_params, _session, socket) do
    socket
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
    do: ["Comedy", "Drama", "Musical", "Science Fiction"]

  def languages(),
    do: ["English", "German", "Italian"]

  def statuses(),
    do: [{"In Stock", "in-stock"}, {"Out Of Stock", "out-of-stock"}]

  # # #

  def movie_form_builder(changeset) do
    Form.new(changeset)
    |> Form.line(fn line ->
      line
      |> Form.text_field(:title, "Title", 4)
    end)
    |> Form.line(fn line ->
      line
      |> Form.text_field(:director, "Director")
      |> Form.text_field(:producer, "Producer")
    end)
    |> Form.line(fn line ->
      line
      |> Form.checkbox_list_field(:genres, "Genres", genres())
    end)
    |> Form.safe()
  end
end
