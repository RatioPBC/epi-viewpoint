defmodule EpiViewpoint.Repo.Migrations.AddIndexToCaseInvestigationStatusColumns do
  use Ecto.Migration

  def change do
    create index(:case_investigations, [:interview_status])
    create index(:case_investigations, [:isolation_monitoring_status])
  end
end
