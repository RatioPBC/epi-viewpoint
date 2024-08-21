defmodule EpiViewpoint.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :dob, :date, null: false
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :seq, :bigserial
      add :tid, :string

      timestamps()
    end
  end
end
