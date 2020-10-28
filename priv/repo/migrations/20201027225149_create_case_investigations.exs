defmodule Epicenter.Repo.Migrations.CreateCaseInvestigations do
  use Ecto.Migration

  def change() do
    create table(:case_investigations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :initiated_by_id, references(:lab_results, on_delete: :nothing, type: :binary_id)
      add :name, :string
      add :person_id, references(:people, on_delete: :nothing, type: :binary_id)
      add :seq, :bigserial
      add :tid, :string

      timestamps()
    end
  end
end
