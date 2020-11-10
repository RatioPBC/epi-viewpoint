defmodule Epicenter.Repo.Migrations.AddIsolationMonitoringDatesToCaseInvestigations do
  use Ecto.Migration

  def change() do
    alter table(:case_investigations) do
      add :isolation_monitoring_end_date, :date
      add :isolation_monitoring_start_date, :date
    end
  end
end
