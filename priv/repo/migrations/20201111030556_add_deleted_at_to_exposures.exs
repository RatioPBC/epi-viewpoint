defmodule EpiViewpoint.Repo.Migrations.AddDeletedAtToExposures do
  use Ecto.Migration

  def change do
    alter table(:exposures) do
      add :deleted_at, :utc_datetime
    end
  end
end
