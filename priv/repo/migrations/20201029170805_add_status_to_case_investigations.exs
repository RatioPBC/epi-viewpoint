defmodule EpiViewpoint.Repo.Migrations.AddStatusToCaseInvestigations do
  use Ecto.Migration

  def change do
    alter table(:case_investigations) do
      add :status, :string, null: false, default: "pending_interview"
    end
  end
end
