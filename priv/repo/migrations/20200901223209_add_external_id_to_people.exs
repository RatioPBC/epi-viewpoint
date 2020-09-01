defmodule Epicenter.Repo.Migrations.AddExternalIdToPeople do
  use Ecto.Migration

  def change() do
    alter table(:people) do
      add :external_id, :string
    end
  end
end
