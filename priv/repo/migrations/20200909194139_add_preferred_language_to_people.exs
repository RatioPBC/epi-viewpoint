defmodule EpiViewpoint.Repo.Migrations.AddPreferredLanguageToPeople do
  use Ecto.Migration

  def change do
    alter table(:people) do
      add :preferred_language, :string
    end
  end
end
