defmodule Epicenter.Cases.LabResult do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person
  alias Epicenter.Extra

  @required_attrs ~w{person_id}a
  @optional_attrs ~w{analyzed_on reported_on request_accession_number request_facility_code request_facility_name result sampled_on test_type tid}a

  @derive {Jason.Encoder, only: [:id] ++ @required_attrs ++ @optional_attrs}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "lab_results" do
    field :analyzed_on, :date
    field :fingerprint, :string
    field :reported_on, :date
    field :request_accession_number, :string
    field :request_facility_code, :string
    field :request_facility_name, :string
    field :result, :string
    field :sampled_on, :date
    field :seq, :integer
    field :test_type, :string
    field :tid, :string

    timestamps(type: :utc_datetime)

    belongs_to :person, Person
  end

  def changeset(lab_result, attrs) do
    lab_result
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> foreign_key_constraint(:person_id, name: :lab_results_person_id_fkey)
    |> change_fingerprint()
  end

  defp change_fingerprint(%Ecto.Changeset{valid?: true} = changeset),
    do: changeset |> change(fingerprint: generate_fingerprint(changeset))

  defp change_fingerprint(changeset),
    do: changeset

  @doc """
  Generate a fingerprint for this lab result, used for de-duplication (via upsert). A multi-column unique index
  could have been used for the upsert, except that nullable columns can't effectively be used for unique indices
  since SQL does not consider two null values to be equal (1 == 1, but NULL != NULL).
  """
  def generate_fingerprint(changeset) do
    fingerprint_fields()
    |> Enum.map(fn field -> changeset |> get_field(field) |> to_string() |> String.downcase() end)
    |> Enum.join(" ")
    |> Extra.String.sha256()
  end

  @doc """
  *** WARNING ***
  If this list of fields changes, the fingerprint column in the table *MAY* not be useful for de-duplication anymore.
  One fix would be to create a second fingerprint column, backfill it, start using it for de-duplication,
  and then drop the original fingerprint column.
  """
  def fingerprint_fields,
    do: ~w{analyzed_on person_id reported_on request_accession_number request_facility_code request_facility_name result sampled_on test_type}a

  defmodule Query do
    import Ecto.Query

    def all() do
      from lab_result in LabResult, order_by: [asc: lab_result.sampled_on, asc: lab_result.seq]
    end

    def display_order() do
      from lab_result in LabResult,
        order_by: [desc_nulls_first: lab_result.sampled_on, desc: lab_result.reported_on, asc: lab_result.seq]
    end

    def opts_for_upsert() do
      [returning: true, on_conflict: {:replace, ~w{updated_at}a}, conflict_target: :fingerprint]
    end
  end
end
