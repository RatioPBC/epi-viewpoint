defmodule EpiViewpoint.Repo.Migrations.DropDemographicsRelatedColumnsFromPeople do
  use Ecto.Migration

  def change do
    alter table(:people) do
      remove :dob, :date
      remove :employment, :string
      remove :ethnicity, :map
      remove :external_id, :string
      remove :fingerprint, :text
      remove :first_name, :string
      remove :gender_identity, {:array, :string}
      remove :last_name, :string
      remove :marital_status, :string
      remove :notes, :string
      remove :occupation, :string
      remove :preferred_language, :string
      remove :race, :string
      remove :sex_at_birth, :string
    end
  end
end
