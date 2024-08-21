defmodule EpiViewpoint.Repo.Migrations.RenameSampleDateInLabResults do
  use Ecto.Migration

  def change do
    rename table(:lab_results), :sample_date, to: :sampled_on
  end
end
