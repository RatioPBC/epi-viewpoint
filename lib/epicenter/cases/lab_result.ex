defmodule Epicenter.Cases.LabResult do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lab_results" do
    field :request_accession_number, :string
    field :request_facility_code, :string
    field :request_facility_name, :string

    timestamps()
  end

  def changeset(lab_result, attrs) do
    lab_result
    |> cast(attrs, [:request_accession_number])
    |> validate_required([:request_accession_number])
  end
end
