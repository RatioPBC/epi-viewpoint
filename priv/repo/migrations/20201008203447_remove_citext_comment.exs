defmodule Epicenter.Repo.Migrations.RemoveCitextComment do
  use Ecto.Migration

  # The citext comment causes problems with GCP cloud_sql import / export
  def change do
    execute "COMMENT ON EXTENSION citext IS NULL", ""
  end
end
