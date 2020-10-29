defmodule Epicenter.Repo.Migrations.AddStatusToCaseInvestigations do
  use Ecto.Migration

  alias Epicenter.Cases.CaseInvestigation

  def change do
    alter table(:case_investigations) do
      add :status, :string, null: false, default: CaseInvestigation.pending_interview_status()
    end
  end
end
