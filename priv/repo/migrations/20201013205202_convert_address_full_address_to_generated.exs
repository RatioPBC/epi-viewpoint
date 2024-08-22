defmodule EpiViewpoint.Repo.Migrations.ConvertAddressFullAddressToGenerated do
  use Ecto.Migration

  def up do
    drop index(:addresses, [:full_address, :person_id])

    alter table(:addresses) do
      remove :full_address
    end

    execute(
      "alter table addresses add column address_fingerprint character varying(255) generated always as
      (encode(sha256((coalesce(street, '') || coalesce(city, '') || coalesce(state, '') || coalesce(postal_code, ''))::bytea), 'hex')) stored"
    )

    create unique_index(:addresses, [:address_fingerprint, :person_id])
  rescue
    e ->
      IO.puts("
        ************************************* MIGRATION FAILED *************************************
        This is likely because you have entries in your addresses table with non-unique values of street,city,state and postal_code for a given person_id.
        They are possibly nil values.

        Please truncate this table (or remove the non-unique rows) before proceeding.")

      reraise e, __STACKTRACE__
  end

  def down do
    drop index(:addresses, [:address_fingerprint, :person_id])

    alter table(:addresses) do
      remove :address_fingerprint
    end

    alter table(:addresses) do
      add :full_address, :string
    end

    create unique_index(:addresses, [:full_address, :person_id])
  end
end
