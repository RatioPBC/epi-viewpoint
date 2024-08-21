defmodule EpiViewpoint.Repo.Migrations.AddNotNullConstraintsToCaseInvestigations do
  use Ecto.Migration

  def up do
    alter table(:case_investigations) do
      modify :person_id, :binary_id, null: false
      modify :initiating_lab_result_id, :binary_id, null: false
    end
  end

  def down do
    alter table(:case_investigations) do
      modify :person_id, :binary_id, null: true
      modify :initiating_lab_result_id, :binary_id, null: true
    end
  end
end
