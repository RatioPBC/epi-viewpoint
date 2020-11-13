defmodule Epicenter.Repo.Migrations.ConvertDemographicStringsToText do
  use Ecto.Migration

  def change do
    alter table(:demographics) do
      modify :employment, :text, from: :string
      modify :external_id, :text, from: :string
      modify :first_name, :text, from: :string
      modify :gender_identity, {:array, :text}, from: {:array, :string}
      modify :last_name, :text, from: :string
      modify :marital_status, :text, from: :string
      modify :notes, :text, from: :string
      modify :occupation, :text, from: :string
      modify :preferred_language, :text, from: :string
      modify :race, :text, from: :string
      modify :sex_at_birth, :text, from: :string
      modify :tid, :text, from: :string
      modify :source, :text, from: :string
    end
  end
end
