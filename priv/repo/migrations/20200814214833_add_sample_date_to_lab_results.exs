defmodule Epicenter.Repo.Migrations.AddSampleDateToLabResults do
  use Ecto.Migration

  def change do
    alter table(:lab_results) do
      add :sample_date, :date, null: false
    end
  end
end
