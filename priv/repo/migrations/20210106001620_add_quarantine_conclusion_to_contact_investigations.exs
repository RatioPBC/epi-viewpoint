defmodule EpiViewpoint.Repo.Migrations.AddQuarantineConclusionToContactInvestigations do
  use Ecto.Migration

  def change do
    alter table(:contact_investigations) do
      add :quarantine_conclusion_reason, :text
      add :quarantine_concluded_at, :utc_datetime
    end
  end
end
