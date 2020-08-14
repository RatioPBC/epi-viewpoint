defmodule Epicenter.Cases.LabResult do
  use Ecto.Schema

  import Ecto.Changeset

  alias Epicenter.Cases.LabResult

  schema "lab_results" do
    field :request_accession_number, :string
    field :request_facility_code, :string
    field :request_facility_name, :string
    field :result, :string
    field :sample_date, :date
    field :tid, :string

    timestamps()
  end

  @required_attrs ~w{result sample_date}a
  @optional_attrs ~w{request_accession_number request_facility_code request_facility_name tid}a

  def changeset(lab_result, attrs) do
    lab_result
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  defmodule Query do
    import Ecto.Query

    def all() do
      from lab_result in LabResult, order_by: [asc: lab_result.sample_date]
    end
  end
end
