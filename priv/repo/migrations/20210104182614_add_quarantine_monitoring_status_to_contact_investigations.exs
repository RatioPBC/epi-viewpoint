defmodule Epicenter.Repo.Migrations.AddQuarantineMonitoringStatusToContactInvestigations do
  use Ecto.Migration

  use Ecto.Migration

  def up() do
    execute("""
    ALTER TABLE contact_investigations
    ADD COLUMN quarantine_monitoring_status TEXT GENERATED ALWAYS AS (
       CASE
         WHEN (quarantine_monitoring_starts_on IS NOT NULL) THEN 'ongoing'
         WHEN (interview_discontinued_at IS NOT NULL) THEN 'pending'
         ELSE 'pending'
       END
    ) STORED
    """)
  end

  def down do
    alter table(:contact_investigations) do
      remove :quarantine_monitoring_status
    end
  end
end
