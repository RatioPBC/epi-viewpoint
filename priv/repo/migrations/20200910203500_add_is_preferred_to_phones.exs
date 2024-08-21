defmodule EpiViewpoint.Repo.Migrations.AddIsPreferredToPhones do
  use Ecto.Migration

  def change() do
    alter table(:phones) do
      add :is_preferred, :boolean
    end
  end
end
