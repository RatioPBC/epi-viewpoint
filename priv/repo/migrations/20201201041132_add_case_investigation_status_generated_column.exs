defmodule EpiViewpoint.Repo.Migrations.AddCaseInvestigationStatusGeneratedColumn do
  use Ecto.Migration

  def up do
    execute("""
    ALTER TABLE case_investigations
    ADD COLUMN interview_status TEXT GENERATED ALWAYS AS (
    CASE
      WHEN interview_started_at IS NULL AND interview_completed_at IS NULL AND interview_discontinued_at is NULL THEN 'pending'
      WHEN interview_discontinued_at IS NOT NULL THEN 'discontinued'
      WHEN interview_started_at IS NOT NULL AND interview_completed_at IS NULL AND interview_discontinued_at is NULL THEN 'started'
      WHEN interview_completed_at IS NOT NULL AND interview_started_at IS NOT NULL AND interview_discontinued_at is NULL THEN 'completed'
    END
    ) STORED
    """)
  end

  def down do
    alter table(:case_investigations) do
      remove :interview_status
    end
  end
end
