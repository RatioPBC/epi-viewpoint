defmodule EpiViewpoint.Repo.Migrations.AddIsPositiveOrDetectedToLabResults do
  use Ecto.Migration

  def up do
    execute(
      "alter table lab_results add column is_positive_or_detected boolean generated always as
      (upper(result) = 'POSITIVE' or upper(result) = 'DETECTED') stored"
    )
  end

  def down do
    alter table(:lab_results) do
      remove :is_positive_or_detected
    end
  end
end
