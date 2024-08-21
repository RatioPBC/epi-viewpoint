defmodule EpiViewpoint.Repo.Migrations.AddDeletedAtToCaseInvestigationNotes do
  use Ecto.Migration

  def change do
    alter table(:case_investigation_notes) do
      add :deleted_at, :utc_datetime
    end
  end
end
