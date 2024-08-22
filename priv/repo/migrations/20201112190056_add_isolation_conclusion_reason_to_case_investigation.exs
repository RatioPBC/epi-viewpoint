defmodule EpiViewpoint.Repo.Migrations.AddIsolationConclusionReasonToCaseInvestigation do
  use Ecto.Migration

  def change do
    alter table(:case_investigations) do
      add :isolation_conclusion_reason, :text
    end
  end
end
