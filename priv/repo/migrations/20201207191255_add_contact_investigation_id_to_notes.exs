defmodule Epicenter.Repo.Migrations.AddContactInvestigationIdToNotes do
  use Ecto.Migration

  def change do
    alter table(:case_investigation_notes) do
      add :exposure_id, references(:exposures, on_delete: :nothing, type: :binary_id)
    end
  end
end
