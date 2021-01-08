defmodule Epicenter.Repo.Migrations.AddApplicationVersionShaToRevisions do
  use Ecto.Migration

  def change do
    alter table(:revisions) do
      add :application_version_sha, :text
    end
  end
end
