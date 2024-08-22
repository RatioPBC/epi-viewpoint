defmodule EpiViewpoint.Repo.Migrations.AddPlaceAddresses do
  use Ecto.Migration

  def change() do
    create table(:place_addresses, primary_key: false) do
      add :address_fingerprint, :text
      add :city, :text
      add :id, :binary_id, primary_key: true
      add :place_id, :binary_id
      add :postal_code, :text
      add :seq, :bigserial
      add :state, :text
      add :street, :text
      add :tid, :text

      timestamps()
    end
  end
end
