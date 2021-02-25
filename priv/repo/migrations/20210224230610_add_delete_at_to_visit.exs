defmodule Epicenter.Repo.Migrations.AddDeleteAtToVisit do
  use Ecto.Migration

  def change do
    alter table(:visits) do
      add :deleted_at, :utc_datetime
    end
  end
end
