defmodule Epicenter.Cases.ImportedFile do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query
  import Epicenter.EctoRedactionJasonEncoder

  alias Epicenter.Cases.ImportedFile

  @required_attrs ~w{file_name}a
  @optional_attrs ~w{contents tid}a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "imported_files" do
    field :contents, :string, redact: true
    field :file_name, :string
    field :seq, :integer
    field :tid, :string

    timestamps(type: :utc_datetime)
  end

  derive_jason_encoder(except: [:seq])

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
