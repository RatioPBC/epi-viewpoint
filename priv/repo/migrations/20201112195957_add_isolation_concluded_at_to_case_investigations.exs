defmodule EpiViewpoint.Repo.Migrations.AddIsolationConcludedAtToCaseInvestigations do
  use Ecto.Migration

  def change do
    alter table(:case_investigations) do
      add :isolation_concluded_at, :utc_datetime
    end
  end
end
