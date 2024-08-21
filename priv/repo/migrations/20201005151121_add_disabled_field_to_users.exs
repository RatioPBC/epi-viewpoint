defmodule EpiViewpoint.Repo.Migrations.AddDisabledFieldToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :disabled, :boolean
    end
  end
end
