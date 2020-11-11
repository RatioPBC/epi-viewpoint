defmodule Epicenter.Repo.Migrations.ConvertExposuresStringsToText do
  use Ecto.Migration

  def change do
    alter table(:exposures) do
      modify :relationship_to_case, :text, from: :string
      modify :tid, :text, from: :string
    end
  end
end
