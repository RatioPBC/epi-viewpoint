defmodule Epicenter.Repo.Migrations.AddFingerprintColumnToLabResults do
  use Ecto.Migration

  def change do
    # set a default so all existing fingerprints are not null;
    # the next migration will undo the default
    alter table(:lab_results) do
      add :fingerprint, :text, null: false, default: fragment("md5(random()::text)")
    end
  end
end
