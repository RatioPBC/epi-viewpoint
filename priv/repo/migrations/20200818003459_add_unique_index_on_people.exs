defmodule EpiViewpoint.Repo.Migrations.AddUniqueIndexOnPeople do
  use Ecto.Migration

  def change do
    alter table(:people) do
      add :fingerprint, :text, null: false
    end

    create unique_index(:people, [:fingerprint])
  end
end
