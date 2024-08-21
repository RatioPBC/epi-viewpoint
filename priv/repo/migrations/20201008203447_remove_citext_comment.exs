defmodule EpiViewpoint.Repo.Migrations.RemoveCitextComment do
  use Ecto.Migration

  # The citext comment causes problems with GCP cloud_sql import / export
  def change do
    if System.get_env("REMOVE_CITEXT_EXTENSION", "false") == "true" do
      execute "COMMENT ON EXTENSION citext IS NULL", ""
    end
  end
end
