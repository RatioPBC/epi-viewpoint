defmodule EpiViewpoint.Repo.Migrations.AddAddressComponentsToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add :street, :string
      add :city, :string
      add :state, :string
      add :postal_code, :string
    end
  end
end
