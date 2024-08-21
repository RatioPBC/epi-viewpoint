defmodule EpiViewpoint.Repo.Migrations.AddArchiveFieldsToPeople do
  use Ecto.Migration

  def change do
    alter table(:people) do
      add :archived_at, :utc_datetime
      add :archived_by_id, references(:users, type: :binary_id, on_delete: :nothing)
    end
  end
end
