defmodule Epicenter.Repo.Migrations.AddVisits do
  use Ecto.Migration

  def change do
    create table(:visits, primary_key: false) do
      add :place_id, references(:places, type: :uuid)
      add :id, :binary_id, primary_key: true
      add :occurred_on, :date
      add :seq, :bigserial
      add :tid, :text

      timestamps()
    end
  end
end
