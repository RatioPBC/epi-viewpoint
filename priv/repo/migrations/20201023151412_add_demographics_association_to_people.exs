defmodule Epicenter.Repo.Migrations.AddDemographicsAssociationToPeople do
  use Ecto.Migration

  def change do
    create table(:demographics, primary_key: false) do
      add :dob, :date
      add :employment, :string
      add :ethnicity, :map
      add :external_id, :string
      add :first_name, :string
      add :gender_identity, {:array, :string}
      add :id, :binary_id, primary_key: true
      add :last_name, :string
      add :marital_status, :string
      add :notes, :string
      add :occupation, :string
      add :person_id, references(:people, type: :uuid), null: false
      add :preferred_language, :string
      add :race, :string
      add :seq, :bigserial
      add :sex_at_birth, :string
      add :source, :string, default: "unknown", null: false
      add :tid, :string

      timestamps()
    end
  end
end
