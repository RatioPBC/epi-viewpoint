defmodule Epicenter.Repo.Migrations.ChangeSeqIntegerColumnsToBigserial do
  use Ecto.Migration

  def up do
    alter table(:imported_files) do
      remove :seq, :integer
      add :seq, :bigserial
    end
  end

  def down do
    alter table(:imported_files) do
      remove :seq, :bigserial
      add :seq, :integer
    end
  end
end
