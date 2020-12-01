defmodule Epicenter.Repo.Migrations.AddCaseInvestigationIsolationMonitoringStatusColumn do
  use Ecto.Migration

  def up do
    execute("""
    ALTER TABLE case_investigations
    ADD COLUMN isolation_monitoring_status TEXT GENERATED ALWAYS AS (
    CASE
      WHEN isolation_concluded_at IS NOT NULL THEN 'concluded'
      WHEN isolation_monitoring_started_on IS NOT NULL THEN 'ongoing'
      WHEN interview_discontinued_at IS NOT NULL THEN 'pending'
      ELSE 'pending'
    END
    ) STORED
    """)
  end

  def down do
    alter table(:case_investigations) do
      remove :isolation_monitoring_status
    end
  end
end
