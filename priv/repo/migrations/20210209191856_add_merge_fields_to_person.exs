defmodule Epicenter.Repo.Migrations.AddMergeFieldsToPerson do
  use Ecto.Migration

  def change do
    alter table(:people) do
      add :merged_into_id, references(:people, type: :binary_id, on_delete: :nothing)
      add :merged_at, :utc_datetime
      add :merged_by_id, references(:users, type: :binary_id, on_delete: :nothing)
    end
  end
end
