defmodule EpiViewpoint.Repo.Migrations.CreateEmails do
  use Ecto.Migration

  def change do
    create table(:emails, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :address, :string, null: false
      add :seq, :bigserial
      add :tid, :string
      add :person_id, references(:people, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:emails, [:person_id])
  end
end
