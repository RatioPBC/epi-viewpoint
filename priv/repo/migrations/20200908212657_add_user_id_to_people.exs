defmodule Epicenter.Repo.Migrations.AddUserIdToPeople do
  use Ecto.Migration

  def up do
    drop table(:assignments)

    alter table(:people) do
      add :assigned_to_id, references(:users, on_delete: :nothing, type: :binary_id)
    end
  end

  def down, do: Epicenter.Repo.Migrations.CreateAssignments.create_assignments_table()
end
