defmodule Epicenter.Repo.Migrations.CreateLabResults do
  use Ecto.Migration

  def change do
    create table(:lab_results, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :request_accession_number, :string
      add :seq, :bigserial

      timestamps()
    end
  end
end
