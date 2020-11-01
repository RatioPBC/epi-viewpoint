defmodule Epicenter.Repo.Migrations.AddColumnsToCaseInvestigations do
  use Ecto.Migration

  def change() do
    alter table(:case_investigations) do
      add :person_interviewed, :string
      add :started_at, :utc_datetime
    end
  end
end
