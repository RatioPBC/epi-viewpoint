defmodule EpicenterWeb.Styleguide.FormLive do
  use EpicenterWeb, :live_view

  import Epicenter.Validation, only: [validate_date: 2]
  import EpicenterWeb.IconView, only: [arrow_down_icon: 0]
  import EpicenterWeb.LiveHelpers, only: [assign_page_title: 2, noreply: 1, ok: 1]

  # fake schema (would be a database-backed schema in real code)
  defmodule Movie do
    use Ecto.Schema

    import Ecto.Changeset

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

    @required_attrs ~w{director in_stock producer title}a
    @optional_attrs ~w{language release_date}a

    def changeset(movie, attrs) do
      movie
      |> cast(attrs, @required_attrs ++ @optional_attrs)
      |> validate_required(@required_attrs)
    end
  end

  # fake context
  defmodule Movies do
    import Ecto.Changeset

    @doc "simulate inserting into the db"
    def create_movie(attrs) do
      %Movie{} |> Movie.changeset(attrs) |> apply_action(:create)
    end
  end

  # a schema just for this page whose fields match the fields of the form, not of the database table(s)
  defmodule MovieForm do
    use Ecto.Schema

    import Ecto.Changeset
    import Epicenter.Validation, only: [validate_date: 2]

    alias Epicenter.DateParser

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
    @optional_attrs ~w{producer status}a

    def changeset(form \\ %MovieForm{}, form_attrs) do
      form
      |> cast(form_attrs, @required_attrs ++ @optional_attrs)
      |> validate_required(@required_attrs)
      |> validate_date(:release_date)
    end

    def movie_attrs(%Ecto.Changeset{} = changeset) do
      case apply_action(changeset, :create) do
        {:ok, struct} -> {:ok, struct |> Map.from_struct() |> convert(:release_date) |> convert(:status, :in_stock)}
        other -> other
      end
    end

    defp convert(attrs, :release_date),
      do: attrs |> Map.update(:release_date, nil, &DateParser.parse_mm_dd_yyyy!/1)

    defp convert(%{status: status} = attrs, :status, :in_stock),
      do: attrs |> Map.put(:in_stock, status == "in-stock") |> Map.delete(:status)
  end

  def mount(_params, _session, socket) do
    socket
    |> assign_page_title("Styleguide: form")
    |> assign(show_nav: false)
    |> assign_form_changeset(MovieForm.changeset(%{}))
    |> assign_movie(nil)
    |> ok()
  end

  def handle_event("save", %{"movie_form" => params}, socket) do
    with %Ecto.Changeset{} = form_changeset <- MovieForm.changeset(params),
         {:movie_form, {:ok, movie_attrs}} <- {:movie_form, MovieForm.movie_attrs(form_changeset)},
         {:movie, {:ok, movie}} <- {:movie, Movies.create_movie(movie_attrs)} do
      socket |> assign_form_changeset(form_changeset) |> assign_movie(movie) |> noreply()
    else
      {:movie_form, {:error, %Ecto.Changeset{valid?: false} = form_changeset}} ->
        socket |> assign_form_changeset(form_changeset) |> noreply()

      {:movie, {:error, _}} ->
        socket |> assign_form_changeset(MovieForm.changeset(params), "An unexpected error occurred") |> noreply()
    end
  end

  # # #

  def statuses(),
    do: [{"In Stock", "in-stock"}, {"Out Of Stock", "out-of-stock"}]

  # # #

  defp assign_movie(socket, movie),
    do: socket |> assign(movie: movie, form_error: nil)

  defp assign_form_changeset(socket, %Ecto.Changeset{valid?: false} = changeset),
    do: socket |> assign_form_changeset(changeset, "Check the errors above")

  defp assign_form_changeset(socket, %Ecto.Changeset{} = changeset, form_error \\ nil),
    do: socket |> assign(form_changeset: changeset, form_error: form_error)
end
