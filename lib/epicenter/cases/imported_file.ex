defmodule Epicenter.Cases.ImportedFile do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Epicenter.Cases.ImportedFile

  @required_attrs ~w{file_name}a
  @optional_attrs ~w{contents tid}a

  @derive {Jason.Encoder, only: @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "imported_files" do
    field :contents, :string
    field :file_name, :string
    field :seq, :integer
    field :tid, :string

    timestamps()
  end

  def changeset(imported_file, attrs) do
    imported_file
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  defmodule Query do
    def all() do
      from imported_file in ImportedFile,
        order_by: [:seq]
    end
  end
end
