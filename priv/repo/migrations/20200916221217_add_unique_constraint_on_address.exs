defmodule Epicenter.Repo.Migrations.AddUniqueConstraintOnAddress do
  use Ecto.Migration

  def change do
    create unique_index(:addresses, [:full_address, :person_id])
  end
end
