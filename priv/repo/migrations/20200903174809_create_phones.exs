defmodule EpiViewpoint.Repo.Migrations.CreatePhones do
  use Ecto.Migration

  def change do
    create table(:phones, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :number, :integer, null: false
      add :seq, :bigserial
      add :tid, :string
      add :type, :string, null: false

      timestamps()
    end
  end
end
