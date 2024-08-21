defmodule EpiViewpoint.Repo.Migrations.AddUniqueConstraintOnPhone do
  use Ecto.Migration

  def change do
    create unique_index(:phones, [:number, :person_id])
  end
end
