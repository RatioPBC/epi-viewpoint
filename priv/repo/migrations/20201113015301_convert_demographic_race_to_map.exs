defmodule Epicenter.Repo.Migrations.ConvertDemographicRaceToMap do
  use Ecto.Migration

  def up do
    alter table(:demographics) do
      remove :race, :text
      add :race, :map
    end
  end

  def down do
    alter table(:demographics) do
      remove :race, :map
      add :race, :text
    end
  end
end
