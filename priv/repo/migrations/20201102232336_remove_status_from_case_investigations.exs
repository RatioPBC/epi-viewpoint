defmodule EpiViewpoint.Repo.Migrations.RemoveStatusFromCaseInvestigations do
  use Ecto.Migration

  def change do
    alter table(:case_investigations) do
      remove :status, :string, null: false, default: "pending_interview"
    end
  end
end
