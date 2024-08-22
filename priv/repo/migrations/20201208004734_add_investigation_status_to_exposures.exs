defmodule EpiViewpoint.Repo.Migrations.AddInvestigationStatusToExposures do
  use Ecto.Migration

  def up do
    execute("""
    ALTER TABLE exposures
    ADD COLUMN interview_status TEXT GENERATED ALWAYS AS (
    CASE
      WHEN interview_discontinued_at is NULL THEN 'pending'
      WHEN interview_discontinued_at IS NOT NULL THEN 'discontinued'
    END
    ) STORED
    """)
  end

  def down do
    alter table(:exposures) do
      remove :interview_status
    end
  end
end
