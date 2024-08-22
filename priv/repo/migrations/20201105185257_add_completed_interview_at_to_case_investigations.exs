defmodule EpiViewpoint.Repo.Migrations.AddCompletedInterviewAtToCaseInvestigations do
  use Ecto.Migration

  def change() do
    alter table(:case_investigations) do
      add :completed_interview_at, :utc_datetime
    end
  end
end
