defmodule EpiViewpoint.Repo.Migrations.MakeSampledOnNullable do
  use Ecto.Migration

  def down do
    alter table(:lab_results) do
      modify :sampled_on, :date, null: false
    end
  end

  def up do
    alter table(:lab_results) do
      modify :sampled_on, :date, null: true
    end
  end
end
