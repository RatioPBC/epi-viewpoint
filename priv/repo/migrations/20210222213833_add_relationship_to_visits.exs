defmodule Epicenter.Repo.Migrations.AddRelationshipToVisits do
  use Ecto.Migration

  def change do
    alter table(:visits) do
      add :relationship, :text
      add :case_investigation_id, references(:case_investigations, type: :uuid)
    end
  end
end
