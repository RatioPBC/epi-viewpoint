defmodule EpiViewpoint.Repo.Migrations.AddContactInvestigationInterviewCompletedAtColumn do
  use Ecto.Migration

  def up() do
    alter table(:contact_investigations) do
      add :interview_completed_at, :utc_datetime
    end

    interview_status_up()
  end

  def down do
    interview_status_down()

    alter table(:contact_investigations) do
      remove :interview_completed_at
    end
  end

  defp interview_status_up() do
    alter table(:contact_investigations) do
      remove :interview_status
    end

    execute("""
    ALTER TABLE contact_investigations
    ADD COLUMN interview_status TEXT GENERATED ALWAYS AS (
      CASE
        WHEN interview_discontinued_at IS NOT NULL THEN 'discontinued'
        WHEN interview_completed_at IS NOT NULL THEN 'completed'
        WHEN interview_started_at IS NOT NULL THEN 'started'
        WHEN interview_discontinued_at is NULL THEN 'pending'
      END
    ) STORED
    """)
  end

  defp interview_status_down do
    alter table(:contact_investigations) do
      remove :interview_status
    end

    execute("""
    ALTER TABLE contact_investigations
    ADD COLUMN interview_status TEXT GENERATED ALWAYS AS (
      CASE
        WHEN interview_discontinued_at IS NOT NULL THEN 'discontinued'
        WHEN interview_started_at IS NOT NULL THEN 'started'
        WHEN interview_discontinued_at is NULL THEN 'pending'
      END
    ) STORED
    """)
  end
end
