defmodule EpiViewpoint.Repo.Migrations.AddAnalysisReportedTestTypeToLabResults do
  use Ecto.Migration

  def change() do
    alter table(:lab_results) do
      add :analyzed_on, :date
      add :reported_on, :date
      add :test_type, :string
    end
  end
end
