defmodule EpiViewpoint.Repo.Migrations.AddInterviewDiscontinueColumnsToExposures do
  use Ecto.Migration

  def change do
    alter table(:exposures) do
      add :interview_discontinued_at, :utc_datetime
      add :interview_discontinue_reason, :text
    end
  end
end
