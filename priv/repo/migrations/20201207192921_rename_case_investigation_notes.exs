defmodule Epicenter.Repo.Migrations.RenameCaseInvestigationNotes do
  use Ecto.Migration

  def change do
    rename table(:case_investigation_notes), to: table(:investigation_notes)
  end
end
