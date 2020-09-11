defmodule Epicenter.Repo.Migrations.AddSampleDateToLabResults do
  use Ecto.Migration

  def change do
    alter table(:lab_results) do
      add :sampled_on, :date, null: false
    end
  end
end
