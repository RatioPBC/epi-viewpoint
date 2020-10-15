defmodule Epicenter.Repo.Migrations.UpdatePersonDemographicEthnicity do
  use Ecto.Migration

  def up do
    alter table(:people) do
      remove :ethnicity, :string
      add :ethnicity, :map
    end
  end

  def down do
    alter table(:people) do
      remove :ethnicity, :map
      add :ethnicity, :string
    end
  end
end
