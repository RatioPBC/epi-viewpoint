defmodule Epicenter.Repo.Migrations.CreateAssignments do
  use Ecto.Migration

  def change do
    create table(:assignments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tid, :string
      add :seq, :integer
      add :person_id, references(:people, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:assignments, [:person_id])
    create index(:assignments, [:user_id])
  end
end
