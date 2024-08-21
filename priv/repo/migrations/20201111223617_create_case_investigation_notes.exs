defmodule EpiViewpoint.Repo.Migrations.CreateCaseInvestigationNotes do
  use Ecto.Migration

  def change do
    create table(:case_investigation_notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :seq, :bigserial
      add :tid, :text
      add :text, :text
      add :author_id, references(:users, on_delete: :nothing, type: :binary_id)

      add :case_investigation_id,
          references(:case_investigations, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:case_investigation_notes, [:author_id])
    create index(:case_investigation_notes, [:case_investigation_id])
  end
end
