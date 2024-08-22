defmodule EpiViewpoint.Repo.Migrations.UpdatePersonDemographicGenderIdentity do
  use Ecto.Migration

  def up do
    alter table(:people) do
      remove :gender_identity, :string
      add :gender_identity, {:array, :string}
    end
  end

  def down do
    alter table(:people) do
      remove :gender_identity, {:array, :string}
      add :gender_identity, :string
    end
  end
end
