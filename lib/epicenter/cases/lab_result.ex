defmodule Epicenter.Cases.LabResult do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.Cases.LabResult
  alias Epicenter.Cases.Person

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "lab_results" do
    field :analyzed_on, :date
    field :reported_on, :date
    field :request_accession_number, :string
    field :request_facility_code, :string
    field :request_facility_name, :string
    field :result, :string
    field :sampled_on, :date
    field :seq, :integer
    field :test_type, :string
    field :tid, :string

    timestamps()

    belongs_to :person, Person
  end

  @required_attrs ~w{person_id result sampled_on}a
  @optional_attrs ~w{analyzed_on reported_on request_accession_number request_facility_code request_facility_name test_type tid}a

  def changeset(lab_result, attrs) do
    lab_result
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
    |> foreign_key_constraint(:person_id, name: :lab_results_person_id_fkey)
  end

  defmodule Query do
    import Ecto.Query

    def all() do
      from lab_result in LabResult, order_by: [asc: lab_result.sampled_on, asc: lab_result.seq]
    end
  end
end
