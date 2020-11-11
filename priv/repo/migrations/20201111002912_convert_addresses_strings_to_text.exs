defmodule Epicenter.Repo.Migrations.ConvertAddressesStringsToText do
  use Ecto.Migration

  def up do
    drop index(:addresses, [:address_fingerprint, :person_id])

    alter table(:addresses) do
      remove :address_fingerprint
    end

    alter table(:addresses) do
      modify :city, :text
      modify :postal_code, :text
      modify :source, :text
      modify :state, :text
      modify :street, :text
      modify :tid, :text
      modify :type, :text
    end

    execute(
      "alter table addresses add column address_fingerprint text generated always as
      (encode(sha256((coalesce(street, '') || coalesce(city, '') || coalesce(state, '') || coalesce(postal_code, ''))::bytea), 'hex')) stored"
    )

    create unique_index(:addresses, [:address_fingerprint, :person_id])
  end

  def down do
    drop index(:addresses, [:address_fingerprint, :person_id])

    alter table(:addresses) do
      remove :address_fingerprint
    end

    alter table(:addresses) do
      modify :city, :string
      modify :postal_code, :string
      modify :source, :string
      modify :state, :string
      modify :street, :string
      modify :tid, :string
      modify :type, :string
    end

    execute(
      "alter table addresses add column address_fingerprint character varying(255) generated always as
      (encode(sha256((coalesce(street, '') || coalesce(city, '') || coalesce(state, '') || coalesce(postal_code, ''))::bytea), 'hex')) stored"
    )

    create unique_index(:addresses, [:address_fingerprint, :person_id])
  end
end
