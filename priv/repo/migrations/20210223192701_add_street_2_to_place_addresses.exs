defmodule EpiViewpoint.Repo.Migrations.AddStreet2ToPlaceAddresses do
  use Ecto.Migration

  def change do
    alter table(:place_addresses) do
      add :street_2, :text
    end
  end
end
