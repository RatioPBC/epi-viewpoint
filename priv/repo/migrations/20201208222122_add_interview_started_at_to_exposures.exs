defmodule Epicenter.Repo.Migrations.AddInterviewStartedAtToExposures do
  use Ecto.Migration

  def change() do
    alter table(:exposures) do
      add :interview_proxy_name, :text
      add :interview_started_at, :utc_datetime
    end

    execute(
      """
      ALTER TABLE exposures
      DROP COLUMN interview_status;
      """,
      """

      ALTER TABLE exposures
      ADD COLUMN interview_status TEXT GENERATED ALWAYS AS (
        CASE
          WHEN interview_discontinued_at is NULL THEN 'pending'
          WHEN interview_discontinued_at IS NOT NULL THEN 'discontinued'
        END
      ) STORED
      """
    )

    execute(
      """
      ALTER TABLE exposures
      ADD COLUMN interview_status TEXT GENERATED ALWAYS AS (
        CASE
          WHEN interview_discontinued_at IS NOT NULL THEN 'discontinued'
          WHEN interview_started_at IS NOT NULL THEN 'started'
          WHEN interview_discontinued_at is NULL THEN 'pending'
        END
      ) STORED
      """,
      """
        ALTER TABLE exposures
        DROP COLUMN interview_status;

      """
    )
  end
end
