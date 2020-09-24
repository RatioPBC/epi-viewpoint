defmodule Epicenter.Repo.Migrations.AddDemographicColumnsToPeople do
  use Ecto.Migration

  def change() do
    alter table(:people) do
      add :gender_identity, :string
      add :employment, :string
      add :ethnicity, :string
      add :marital_status, :string
      add :notes, :text
      add :occupation, :string
      add :race, :string
      add :sex_at_birth, :string
    end
  end
end
