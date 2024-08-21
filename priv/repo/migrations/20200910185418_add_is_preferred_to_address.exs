defmodule EpiViewpoint.Repo.Migrations.AddIsPreferredToAddress do
  use Ecto.Migration

  def change() do
    alter table(:addresses) do
      add :is_preferred, :boolean
    end
  end
end
