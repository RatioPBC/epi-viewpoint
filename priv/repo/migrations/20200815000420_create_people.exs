defmodule Epicenter.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :dob, :date, null: false
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :tid, :string

      timestamps()
    end
  end
end
