defmodule EpiViewpoint.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :seq, :bigserial
      add :tid, :string
      add :username, :string, null: false

      timestamps()
    end

    create unique_index(:users, [:username])
  end
end
