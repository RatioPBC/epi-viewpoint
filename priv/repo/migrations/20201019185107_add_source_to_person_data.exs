defmodule Epicenter.Repo.Migrations.AddSourceToPersonData do
  use Ecto.Migration

  def change do
    alter table(:lab_results) do
      add :source, :string, default: "unknown", null: false
    end

    alter table(:addresses) do
      add :source, :string, default: "unknown", null: false
    end

    alter table(:phones) do
      add :source, :string, default: "unknown", null: false
    end

    alter table(:emails) do
      add :source, :string, default: "unknown", null: false
    end
  end
end
