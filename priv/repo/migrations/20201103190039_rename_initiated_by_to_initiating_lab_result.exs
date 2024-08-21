defmodule EpiViewpoint.Repo.Migrations.RenameInitiatedByToInitiatingLabResult do
  use Ecto.Migration

  def change do
    rename table(:case_investigations), :initiated_by_id, to: :initiating_lab_result_id
  end
end
