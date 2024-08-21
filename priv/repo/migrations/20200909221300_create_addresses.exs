defmodule EpiViewpoint.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :full_address, :string, null: false
      add :type, :string
      add :seq, :bigserial
      add :tid, :string
      add :person_id, references(:people, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:addresses, [:person_id])
  end
end
