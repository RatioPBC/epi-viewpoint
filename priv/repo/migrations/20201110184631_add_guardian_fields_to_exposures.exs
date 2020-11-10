defmodule Epicenter.Repo.Migrations.AddGuardianFieldsToExposures do
  use Ecto.Migration

  def change do
    alter table(:exposures) do
      add :guardian_name, :text
      add :guardian_phone, :text
    end
  end
end
