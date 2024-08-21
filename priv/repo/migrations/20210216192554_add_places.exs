defmodule EpiViewpoint.Repo.Migrations.AddPlaces do
  use Ecto.Migration

  def change do
    create table(:places, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :text
      add :seq, :bigserial
      add :tid, :text
      add :type, :text

      timestamps()
    end
  end
end
