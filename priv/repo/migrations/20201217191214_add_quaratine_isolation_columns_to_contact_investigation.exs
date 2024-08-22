defmodule EpiViewpoint.Repo.Migrations.AddQuaratineIsolationColumnsToContactInvestigation do
  use Ecto.Migration

  def change do
    alter table(:contact_investigations) do
      add :quarantine_monitoring_starts_on, :date
      add :quarantine_monitoring_ends_on, :date
    end
  end
end
