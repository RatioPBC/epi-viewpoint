defmodule EpiViewpoint.Repo.Migrations.CreateUniqueIndexOnLabResultsFingerprint do
  use Ecto.Migration

  def change do
    # remove the default so that new rows can't be inserted without a fingerprint
    alter table(:lab_results) do
      modify :fingerprint, :text, null: false, default: nil
    end

    create unique_index(:lab_results, [:fingerprint])
  end
end
